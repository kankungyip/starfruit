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
# Dynamic Controller

# Module dependencies
fs = require 'fs'
url = require 'url'
path = require 'path'
util = require 'util'
domain = require 'domain'
{Readable} = require 'stream'
querystring = require 'querystring'

# First char upper
String::ucfirst = -> @charAt(0).toUpperCase() + @substr(1)

# function -> script
Function::script = (argv) ->
  env = ''
  for key, val of argv
    value = ''
    switch typeof val
      when 'string' then value += "\"#{ val.replace /["|']/g, '\\"' }\""
      when 'object' then value += JSON.stringify val
      else value += val.toString()
    env += "var #{key}=#{value};"
  return "(function(){#{env}(#{@toString()})()})();"

# Application script
application = ->
  # application object
  app = window.app = (event) ->
    type = event.type
    id = if event.target?.id then event.target.id else ''
    unless app[id]
      app[id] = event.target
      app[id]._sync = true
      app[id]._remote = {}
    sender = app[id]
    window.event = event
    return sender._remote[type]() if (typeof sender._remote[type] is 'function') and (sender._sync isnt true)

    # getting event script
    app._callback = null
    $.getScript location.pathname + 
      '?_id=EVENT' +
      '&_key=' +
      '&id=' + id +
      '&type=' + type
    .done ->
      sender._sync = app._sync
      sender._remote[type] = app._callback
      sender._remote[type]() if typeof sender._remote[type] is 'function'

  # application events
  app.click = -> app _event
  app.keypress = -> app _event

  # getting user event
  window.constructor::__defineGetter__ '_event', ->
    func = arguments.callee.caller
    while func?
      arg = func.arguments[0]
      return arg if arg instanceof Event
      func = func.caller
    return null

# prototype
module.exports = class Controller

  # Constructor
  constructor: ->
    # sandbox runtime
    @_sandbox = domain.create()
    @_sandbox.on 'error', (err) =>
      @_finish = null
      @_error? err
    # application's event callback
    @_sync = false
    @_callback = ''

  # End buffer
  end: ->
    if @_callback.length > 0
      @_buffer?.write "
        window.app._sync = #{@_sync.toString()};
        window.app._callback = function() {
          #{@_callback}
        };
      "
    @_buffer?.end.apply @_buffer, arguments

  # Write chunk to buffer
  write: -> @_buffer?.write.apply @_buffer, arguments

  # Write status and headers
  writeHead: -> @_buffer?.writeHead.apply @_buffer, arguments

  # Receive stream
  receive: (stream, encoding = 'utf8') ->
    return unless stream instanceof Readable
    stream.setEncoding = encoding if typeof encoding is 'string'
    stream.pipe @_buffer if @_buffer

  # Render content
  render: -> @end 'I love starfruit!' # default

  # Sandbox runing
  sandbox: (callback) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_sandbox?.run callback

  # Catch the error
  error: (callback) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_error = callback

  # Sync client callback
  sync: -> @_sync = true

  # User event script
  script: (callback, argv) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_callback += callback.script argv

  # Respond client
  _do: (req, @_buffer) ->
    # parse url
    req.setEncoding 'utf8'
    urls = url.parse req.url
    @query = querystring.parse urls.query
    @query.raw = urls.query

    # response buffer
    @_buffer.removeAllListeners 'error'
    @_buffer.on 'error', (err) => @_error? err

    # default content
    return @render() if !@query.raw or @query.raw.length < 1

    # application content
    @writeHead 200, "Content-Type": "text/javascript;charset=utf-8"
    return @end application.script() if @query.raw is 'script'
    # post data
    data = ''
    req.addListener 'data', (chunk) -> data += chunk
    req.addListener 'end', =>
      @_form = querystring.parse data
      @_form.raw = data
      switch @query._id
         when 'EVENT' then @_event()

  # Application's event
  _event: ->
    type = @query.type
    index = type.length
    index = 3 if (type.indexOf('key') is 0) or (type.indexOf('dbl') is 0)
    index = 5 if type.indexOf('mouse') is 0
    methodName = @query.id + type.substr(0, index).ucfirst() + type.substr(index).ucfirst()
    return @end() if typeof @[methodName] isnt 'function'
    @query = null
    @[methodName]()
