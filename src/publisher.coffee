class Publisher
  constructor: (@_options) ->

  _ixUpdateKey: (channel) -> "socket_thing-ixUpdate-#{channel}"
  _queueKey: (channel) -> "socket_thing-queue-#{channel}"
  
  _recordToQueue: (channel, message, next) ->
    @_options.redis.multi()
      .incr(@_ixUpdateKey(channel))
      .lpush(@_queueKey(channel), JSON.stringify(message))
      .exec(next)
    @_trimQueue(channel)

  _trimQueue: (channel) ->
    @_options.redis.ltrim(@_queueKey(channel), 0, @_options.queueLengthMax)

  send: (channel, tags, message) ->
  
  sendAll: (message) ->

  getIxLastUpdate: (channel, next) ->
    @_options.redis.get @_ixUpdateKey(channel), next

  _publishInvoke: (fx, args...) ->
    @_options.redis.publish("socket_thing", JSON.stringify({ fx, args }))

module.exports = Publisher
