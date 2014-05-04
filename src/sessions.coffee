class Sessions
  constructor: (@_options) ->
    @channel_tag_idClient = {}
    # idClient:
    #   permissionsObj
    #   channels:
    #     channel...:
    #       tags:
    #         tag...: 1
    #       permissionTags
    @socketData = {}

  subscribe: (channel, tags, idClient, next) ->
    onPermissionTags = (err, permissionsObj) =>
      socketData.channels[channel].permissionTags = permissionsTags

      @unsubscribe(channel, idClient)

      socketData = @getCreateSocketData(idClient)
      socketData.channels[channel] ?= @_createChannelData()
      tagsObj = {}
      for tag in tags
        tagsObj[tag] = 1
      socketData.channels[channel].tags = tagsObj
      for tag in tags
        @channel_tag_idClient[channel][tag][idClient] = 1

      next()

    fxPermissionTags = @_options.fxPermissionTags
    if fxPermissionTags.length == 2
      # Asynchronous fxPermissionTags
      fxPermissionTags socketData.permissionsObj, onPermissionTags
    else
      # Synchronous fxPermissionTags
      onPermissionTags(null, fxPermissionTags(socketData.permissionsObj))

  unsubscribe: (channel, idClient) ->
    socketData = @getCreateSocketData(idClient)

    tagsObj = socketData.channels[channel].tags
    for tag of tagsObj
      delete @channel_tag_idClient[channel][tag][idClient]

    delete socketData.channels[channel]

  getCreateSocketData: (idClient) ->
    @socketData[idClient] ?=
      permissionObj: {}
      channels: {}

  _createChannelData: ->
    tags: {}
    permissionTags: []

  setPermissionsObj: (idClient, permissionsObj) ->
    @getCreateSocketData(idClient).permissionObj = permissionObj

module.exports = Sessions
