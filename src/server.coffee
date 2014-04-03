#
#       _/_/_/    _/                              _/_/                      _/    _/      
#    _/        _/_/_/_/    _/_/_/  _/  _/_/    _/      _/  _/_/  _/    _/      _/_/_/_/   
#     _/_/      _/      _/    _/  _/_/      _/_/_/_/  _/_/      _/    _/  _/    _/        
#        _/    _/      _/    _/  _/          _/      _/        _/    _/  _/    _/         
# _/_/_/        _/_/    _/_/_/  _/          _/      _/          _/_/_/  _/      _/_/      
#
# MIT Licensed
# Copyright (c) 2014 Kan Kung-Yip
#
# HTTP Server

# Module dependencies
fs = require 'fs'
url = require 'url'
path = require 'path'
http = require 'http'
util = require 'util'
cluster = require 'cluster'
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

  # Handle the error
  @error: (callback) ->
    @_error = callback if typeof callback is 'function'

  # Getting or setting server response content type
  @contentType: (extname, type) ->
    @_types ?=
      ".html": "text/html",
      ".htm": "text/html",
      ".js": "text/javascript",
      ".css": "text/css",
      ".jpeg": "image/jpeg",
      ".jpg": "image/jpeg",
      ".png": "image/png",
      ".gif": "image/gif"
    @_types[extname] = type if typeof type is 'string'
    @_types[extname] if @_types.hasOwnProperty extname
    return 'text/plain'

  # Getting now date and time
  @_datetime: ->
    date = new Date()
    year = date.getFullYear()
    month = date.getMonth() + 1
    month = '0' + month if month < 10
    day = date.getDate()
    day = '0' + day if day < 10
    [
      util.format '%s-%s-%s', year, month, day
      date.toLocaleTimeString()
    ]

  # Respond client's request
  @respond: (req, res) ->
    # timer for response
    responseTime = new Date().getTime()
    res.on 'finish', =>
      res.responseTime = new Date().getTime() - responseTime # response time.
      @log req, res

    # getting server status code page content
    status = (code, text) =>
      res.writeHead code, "Content-Type": "text/html;charset=utf-8"
      # custom server status code response
      file = path.join process.cwd(), @static, "_#{ code }.html"
      if fs.existsSync file
        rs = fs.createReadStream file
        rs.pipe res
      # default server status code response
      else
        res.end util.format '<title>%s %s</title><center><p><br><br></p><h1>%s %s</h1><p><i>pilot.js<i></p></center>',
          code, text, code, text

    # record error
    file = false
    pool = (err) =>
      [date, time] = @_datetime()
      text = err.toString()
      index = text.indexOf ':'
      title = text.substr 0, index
      message = text.substr index + 2
      err =
        date: date
        time: time
        title: title
        message: message
        request:
          method: req.method
          url: req.url
        response:
          file: file
          charset: err.charset
      cluster.worker.send err
      @_error? err

    # response timeout, default 30s
    res.setTimeout @timeout * 1000, ((callback) ->
      return -> callback 503, 'Service Unavailable'
    )(status)

    # getting request pathname
    pathname = url.parse(req.url).pathname.toLowerCase()

    # route to static contents
    staticfile = path.join process.cwd(), @static, pathname
    extname = path.extname staticfile
    staticfile = path.join staticfile, @index if extname.length < 1
    if fs.existsSync staticfile
      file = staticfile
      res.writeHead 200, "Content-Type": @contentType extname
      rs = fs.createReadStream staticfile
      rs.pipe res

    # route to dynamic contents
    if file is false
      dynamicfile = path.join process.cwd(), @dynamic, pathname + '.js'
      if fs.existsSync dynamicfile
        file = dynamicfile
        # load controller
        controller = require dynamicfile
        controller = new controller() if typeof controller is 'function'
        # catch error
        controller.error (err) =>
          pool err
          # 500 Internal Server Error
          status 500, 'Internal Server Error'
        # finish request
        controller.finish (statusCode, contentType, charset) ->
          if statusCode? and contentType?
            contentType += ';charset=' + charset if charset?.length > 0
            res.writeHead statusCode, "Content-Type": contentType
            controller.pipe? res
        # controller respond client request
        quest = {}
        controller.respond quest

    # 404 Not Found
    if file is false
      status 404, 'Not Found'
      pool new Error util.format 'Can not found file %s and %s', staticfile, dynamicfile

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
    [date, time] = @_datetime()
    msg = util.format '%s - %s', time, msg

    # stdout message
    console.log msg if env isnt 'production'
    @_logFile?.write util.format '%s %s\n', date, msg.replace /\x1b\[[0-9;]*m/g, ''

  # Debug message
  @debug: (arg1) ->
    return if typeof arg1 isnt 'string' or env is 'production'
    msg = 'DEBUG: ' + util.format.apply(util, arguments) + '\n'
    process.stderr.write msg if env isnt 'production'
