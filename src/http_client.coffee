EventEmitter = require 'events'
{
  User,
  TextMessage,
} = require 'hubot'

{
  EventConnected,
  EventMessage,
  EventError,
} = require './client_event'

class HTTPClient extends EventEmitter
  run: (@tokens, @robot) ->
    @robot.router.post '/bearychat', @receiveMessageCallback.bind(@)

    @emit EventConnected

  sendMessage: (envelope, message) ->
    {_,token} = envelope.user
    url = "https://bearychat.com/api/rtm/message"
    message = Object.assign {token:token},message
    message = JSON.stringify message

    @robot.http(url)
      .header('Content-Type', 'application/json')
      .post(message) (err, res, body) =>
        @robot.logger.debug(body)
        @emit(EventError, err) if err

  packMessage: (isReply, envelope, [text, opts]) ->
    text = "#{envelope.user.name}: #{text}" if isReply
    Object.assign opts || {},{sender: envelope.user.sender,vchannel: envelope.user.vchannel,text: text}


  receiveMessageCallback: (req, res) ->
    body = req.body
    unless body
      @robot.logger.error('No body provided for this request')
      return

    unless @isValidToken(body.token)
      res.status(404).end()
      @robot.logger.error('Invalid token sent for this request')
      return

    res.status(200).end()

    text = "#{@robot.name} #{body.text}"
    user = new User(body.sender, {
      team: body.subdomain,
      token: body.token,
      sender: body.sender,
      vchannel: body.vchannel,
      name: body.username,
    })

    @emit(EventMessage, new TextMessage(user, text, body.key))

  isValidToken: (token) ->
    @tokens.indexOf(token) != -1

module.exports = HTTPClient
