ws = require('ws')
uuid = require('node-uuid')
messages = require('./messages')
redis = require('redis')
cookie = require('cookie')
Publisher = require('./publisher')
Sessions = require('./sessions')

class Server
  constructor: ->
    @clientsById = {}
    @_options =
      permission_tags: []
      redis: redis.createClient(6379, 'localhost')
      fxPermission: -> {}
      fxPermissionTags: -> []
      queueLengthMax: 100
    @publisher = new Publisher(@_options)
    @sessions = new Sessions(@_options)

  listen: (server) ->
    @wss = new ws.Server({ server, path: '/socket_thing/socket' })
    @wss.on 'connection', @_onConnection.bind(@)

  send: (channel, tags, message) ->

  _onConnection: (client) ->
    client.id = uuid.v4()
    @clientsById[client.id] = client
    client.on 'error', (err) =>
      console.warn { id: client.id, msg: "ws client threw error: #{err?.message ? err}" }
      client.close()

    client.respondedToPing = true
    client.pingTimer = setInterval(@_pingClient.bind(@), 20000, client)

    req = client.upgradeReq
    urlObj = url.parse(req.url)
    query = querystring.parse(urlObj.query)
    if req.headers.cookie?
      cookies = cookie.parse(req.headers.cookie)
    else
      cookies = {}

    queue = []
    queueMessage = (data) =>
      queue.push data
    client.on 'message', queueMessage

    fxPermission = @_options.fxPermission

    setPermissionObj = (permissionObj) =>
      client.permissionObj = permissionObj
      client.removeListener 'message', queueMessage
      fxOnMessage = @_onMessage(client)
      client.on 'message', fxOnMessage
      for message in queue
        fxOnMessage(message)

    if fxPermission.length == 3
      # Asynchronous fxPermission
      fxPermission query, cookies, (err, permissionObj) ->
        if err?
          client.close(1000, "permission check failed")
          return
        setPermissionObj(permissionObj)
    else
      # Synchronous fxPermission
      setPermissionObj(fxPermission(query, cookies))

  _onMessage: (client) ->
    (data) =>
      # Maybe not a ping response, but all we care about is that they're alive
      client.respondedToPing = true

      try
        msg = JSON.parse(data)
      catch err
        console.warn { id: client.id, msg: "Could not parse message", data }
        @_sendJSON(client, { error: "Could not parse message as JSON: #{ data }" })
        return

      respond = (err, result) =>
        response = { reqid: msg.reqid }
        if err
          response.error = err
        else
          response.result = result
        @_sendJSON(client, { response })
      
      if !messages[msg.type]
        console.warn { id: client.id, msg: "Bad message", data: msg }
        return respond("Unrecognized message type")

      args = {}
      for arg in messages[msg.type].arguments
        if !msg[arg]?
          console.warn { id: client.id, msg: "Missing argument", arg }
          return respond("Missing argument: #{ arg }")
        args[arg] = msg[arg]
      
      switch msg.type
        when "subscribe"
          @sessions.subscribe args.channel, args.tags, client.id, (err) ->
            if err?
              respond(err)
              return

            @publisher.getIxLastUpdate args.channel, (err, ixLastUpdate) ->
              if err?
                respond(err)
              else
                respond(null, ixLastUpdate)
        when "unsubscribe"
          if !(err = @sessions.unsubcribe(args.channel, client.id))?
            respond(null, true)
          else
            respond(err)
        when "getSubscriptions"
          subs = @sessions.getCreateSocketData(client.id)
          respond(null, subs)
        when "ping"
          respond(null, true)
        else
          console.warn { id: client.id, msg: "Bad message", data: msg }
          respond("Unrecognized message type")

  _pingClient: (client) ->
    if !client.respondedToPing
      client.close(1000, "no ping response")
      return
    client.respondedToPing = false
    @_sendJSON(client, { ping: {} })

  _sendJSON: (client, obj) =>
    if client.readyState == ws.OPEN
      client.send JSON.stringify(obj)
    else
      client.close(1000, "socket closed when trying to send message")

  sendAll: (message) ->
    @publisher.sendAll(message)

  send: (channel, tags, message) ->
    @publisher.send(channel, tags, message)

module.exports = Server
