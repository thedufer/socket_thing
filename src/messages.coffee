module.exports =
  subscribe:
    desc: "Subscribe to any number of tags on a channel.  First unsubscribes from all tags on that channel."
    returns: "The ixLastUpdate for the channel you have subscribed to"
    arguments: [
      "channel"
      "tags"
    ]
  unsubscribe:
    desc: "Unsubscribe from all tags on a channel."
    returns: "true"
    arguments: ["channel"]
  getSubscriptions:
    desc: "Get an object showing this socket's current subscriptions."
    returns: "An object describing the socket's current subscriptions and logged-in user"
    arguments: []
  ping:
    returns: "true"
    desc: "Use to check if the socket is open.  Always returns true."
    arguments: []
