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

  # Catch the error
  @error: (callback) ->
    if typeof callback isnt 'function'
      msg = typeof(callback) + ' is not a function'
      err = new TypeError msg
      throw err
    @_error = callback

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
    return @_types[extname] = type if typeof type is 'string'
    return @_types[extname] if typeof @_types[extname] is 'string'
    return 'text/plain'

  # Listening for server
  @listen: ->
    server = http.createServer @
    server.listen.apply server, arguments

  # Message logger
  @log: (arg1, arg2) ->
    if @_logFile or env isnt 'production'
      # formator for message
      @_logFormat ?= (req, res) ->
        util.format '%s %s %s ' + style.over('(%sms)'),
          style.tag(req.method),
          req.url,
          style.int(res.statusCode),
          res.elapsedTime
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
  @_respond: (req, res) ->
    # timer for response
    elapsedTime = new Date().getTime()
    res.on 'finish', =>
      res.elapsedTime = new Date().getTime() - elapsedTime
      @log req, res

    # record error
    file = false
    controller = null
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
          statusCode: res.statusCode
          elapsedTime: if res.elapsedTime then res.elapsedTime else new Date().getTime() - elapsedTime
      cluster.worker.send err
      @_error? err

    # getting server status code page content
    status = (code, text) =>
      res.writeHead code, "Content-Type": "text/html;charset=utf-8"
      # custom server status code response
      codefile = path.join process.cwd(), @static, "_#{ code }.html"
      if fs.existsSync codefile
        file = codefile
        rs = fs.createReadStream codefile
        rs.pipe res
      # default server status code response
      else
        res.end util.format '<title>%s %s</title><center><p><br><br></p><h1>%s %s</h1><p><i>pilot.js<i></p></center>',
          code, text, code, text

    # response timeout, default 30s
    res.setTimeout @timeout * 1000, ->
      status 503, 'Service Unavailable'
      pool new Error 'Service unavailable'

    # getting request pathname
    pathname = url.parse(req.url).pathname.toLowerCase()

    # route to static contents
    staticfile = path.join process.cwd(), @static, pathname
    extname = path.extname staticfile
    staticfile = path.join staticfile, @default + '.html' if extname.length < 1
    if fs.existsSync staticfile
      file = staticfile
      res.writeHead 200, "Content-Type": @contentType extname
      rs = fs.createReadStream staticfile
      rs.pipe res

    # route to dynamic contents
    if file is false
      dynamic = path.join process.cwd(), @dynamic, pathname
      dynamicfile = dynamic
      extname = path.extname dynamicfile
      dynamicfile = dynamicfile + '.js' if extname.length < 1
      dynamicfile = path.join dynamic, @default + '.js' unless fs.existsSync dynamicfile
      if fs.existsSync dynamicfile
        file = dynamicfile
        controller = require dynamicfile
        controller = new controller() if typeof controller is 'function'
        controller.error (err) ->
          status 500, 'Internal Server Error'
          pool err
        controller._do req, res

    # 404 Not Found
    if file is false
      status 404, 'Not Found'
      pool new Error util.format 'Can not found files in %s folder or %s folder.', @static, @dynamic
