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
  app = window.app = (event, selector) ->
    window.event = event
    app._url = "#{location.pathname}?selector=#{selector}&_id=event&_key="
    return app._selector[selector]() if typeof app._selector[selector] is 'function'
    # getting event script
    $.getScript app._url + 'script'
    .done -> app._selector[selector]() if typeof app._selector[selector] is 'function'

  # application events
  app._selector = {}
  app.selector = (selector) -> app _event, selector

  # core data
  app.core = {
    # base data carrier and catcher
    base: (model) ->
      # get value from dom element
      get = (elem, name) ->
        switch name.toString()
          when 'text' then value = elem.text()
          when 'html' then value = elem.html()
          when 'value' then value = elem.val()
          else value = elem.attr name
        return value
      # user data
      data = {}
      for id, attrs of model
        elem = $('#' + id)
        data[id] = {}
        unless $.isArray attrs then data[id] = get elem, attrs
        else data[id][name] = get elem, name for name in attrs
      # set data
      carrier = (data) ->
        # set value to dom element
        set = (elem, name, value) ->
          switch name.toString()
            when 'text' then elem.text value
            when 'html' then elem.html value
            when 'value' then elem.val value
            else elem.attr name, value
        # user data
        for id, attrs of model
          elem = $('#' + id)
          continue unless data[id]
          unless $.isArray attrs then set elem, attrs, data[id]
          else set elem, name, data[id][name] for name in attrs
      # post data
      $.post app._url + 'data', (JSON.stringify data), carrier, 'json'
  }

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
    @_callback = ''

  # End buffer
  end: ->
    return if @_end is true
    switch @query._key
      when 'script' then @_buffer?.write "app._selector['#{@query.selector}'] = function() { #{@_callback} };"
      when 'data' then @_buffer?.write JSON.stringify @data
    @_buffer?.end.apply @_buffer, arguments
    @_end = true

  # Write chunk to buffer
  write: -> @_buffer?.write.apply @_buffer, arguments if @_end isnt true

  # Write status and headers
  writeHead: -> @_buffer?.writeHead.apply @_buffer, arguments if @_end isnt true

  # Receive stream
  receive: (stream, encoding = 'utf8') ->
    return if @_end is true
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

  # User event script
  remote: (callback, argv) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_callback += callback.script argv

  # parse data raw
  parse: (raw) -> return JSON.parse raw

  # User date model
  model: (template, model) ->
    # user template
    if (typeof template is 'object') and (template isnt null)
      model = template
      template = 'base'
    # data model
    if (typeof model is 'object') and (model isnt null) and (!util.isArray model)
      return if @query._key isnt 'script'
      # user template
      if typeof template is 'function'
        @remote (-> func model), func: template, model: model
      # template library
      else
        switch template
          when 'base' #, ... more templates
            @remote (-> app.core[key] model), key: template, model: model
          # default
          else @remote (-> app.core['base'] model), model: model
      @end()

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
    @writeHead 200, "Content-Type": "text/plain;charset=utf-8"
    return @render() if !@query.raw or @query.raw.length < 1
    # application content
    return @end application.script() if @query.raw is 'script'
    # post data
    raw = ''
    req.on 'data', (chunk) -> raw += chunk
    req.on 'end', =>
      @data = @parse raw if raw.length > 0
      switch @query._id
        when 'event'
          selector = @query.selector
          @[selector]() if typeof @[selector] is 'function'
          @end()
