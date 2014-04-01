# Starfruit - HTTPServer
#
# MIT Licensed
#
# Copyright (c) 2014 Kan Kung-Yip

# Module dependencies
fs = require 'fs'
url = require 'url'
path = require 'path'
http = require 'http'
util = require 'util'
{Writable} = require 'stream'

# environment
env = process.env.NODE_ENV or 'development'

# styles
style =
  tag: (str) -> '\x1b[32m' + str + '\x1b[0m'
  int: (str) -> '\x1b[34m' + str + '\x1b[0m'
  over: (str) -> '\x1b[36m' + str + '\x1b[0m'

# prototype
module.exports = class Server

  # methods

  # Getting or setting server response content type
  @contentType = (extname, type) =>
    @_types ?=
      ".html": "text/html", ".htm": "text/html", ".js": "text/javascript", ".css": "text/css",
      ".jpeg": "image/jpeg", "jpg": "image/jpeg", ".png": "image/png", "gif": "image/gif"
    @_types[extname] = type if typeof type is 'string'
    @_types[extname] if @_types.hasOwnProperty extname
    return 'text/plain'

  # Respond client's request
  @respond: (req, res) ->

    # start timer for response
    responseTime = new Date().getTime()

    # getting server status code page content
    status = (code, text, res) =>
      res.writeHead code, "Content-Type": 'text/html'
      # custom server status code response
      file = path.join process.cwd(), @static, "_#{ code }.html"
      if fs.existsSync file
        rs = fs.createReadStream file
        rs.pipe res
      # default server status code response
      else
        res.write util.format '<title>%s %s</title><center><p><br><br></p><h1>%s %s</h1><p><i>pilot.js<i></p></center>',
          code, text, code, text
        res.end()

    # response timeout, default 30s
    res.setTimeout @timeout * 1000, ((callback, res) ->
      return ->
        callback 503, 'Service Unavailable', res
    )(status, res)

    # default server status code
    res.statusCode = 404

    # getting request pathname
    pathname = url.parse(req.url).pathname.toLowerCase()

    # route to static contents
    filename = path.join process.cwd(), @static, pathname
    extname = path.extname filename
    filename = path.join filename, @index if extname.length < 1
    if fs.existsSync filename
      res.writeHead 200, "Content-Type": @contentType extname
      rs = fs.createReadStream filename
      rs.pipe res

    # 404 Not Found
    status 404, 'Not Found', res if res.statusCode is 404

    # logging infomation
    res.responseTime = new Date().getTime() - responseTime # response time.
    @log req, res

  # Listening for server
  @listen: ->
    server = http.createServer @
    server.listen.apply server, arguments

  # Formator for message
  @_logFormat = (req, res) ->
    # NODE_ENV=production.
    if env is 'production'
      util.format '%s %s %s ' + style.over('(%sms)'),
        style.tag(req.method),
        req.url,
        style.int(res.statusCode),
        res.responseTime
    # NODE_ENV=development.
    else
      util.format '%s %s %s ' + style.over('(%sms)'),
        style.tag(req.method),
        req.url,
        style.int(res.statusCode),
        res.responseTime

  # Message logger
  @log: (arg1, arg2) ->

    # setting log file
    return @_logFile = arg1 if arg1 instanceof Writable

    # setting log event
    arg2 = arg1 if typeof arg1 is 'function'
    return @_logFormat = arg2 if typeof arg2 is 'function'

    # format string
    msg = util.format.apply(util, arguments) + '\n' if typeof arg1 is 'string'

    # format request object
    if arg1 instanceof http.IncomingMessage and arg2 instanceof http.ServerResponse
      msg = @_logFormat arg1, arg2

    # error is not string
    return if typeof msg isnt 'string'

    # add the timestamp
    date = new Date()
    year = date.getFullYear()
    month = date.getMonth() + 1
    month = '0' + month if month < 10
    day = date.getDate()
    day = '0' + day if day < 10
    msg = util.format '%s - %s', date.toLocaleTimeString(), msg

    # stdout message
    console.log msg if env isnt 'production'
    @_logFile?.write util.format '%s-%s-%s %s\n', year, month, day, msg.replace /\x1b\[[0-9;]*m/g, ''

  # Debug message
  @debug: (arg1) ->
    return if typeof arg1 isnt 'string' or env is 'production'
    msg = 'DEBUG: ' + util.format.apply(util, arguments) + '\n'
    process.stderr.write msg if env isnt 'production'
