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
    return app.callers[selector]() if typeof app.callers[selector] is 'function'
    # getting event script
    $.getScript app._url + 'script'
    .done (script) -> app.callers[selector]() if typeof app.callers[selector] is 'function'

  # application events
  app.callers = {}
  app.selector = (selector) -> app _event, selector

  # core data
  app.core = {
    # base data carrier and catcher
    base: (model) ->
      # set value to dom element
      set = (elem, name, value) ->
        switch name.toString()
          when 'text' then elem.text value
          when 'html' then elem.html value
          when 'value' then elem.val value
          else elem.attr name, value
      # get value from dom element
      get = (elem, name) ->
        switch name.toString()
          when 'text' then value = elem.text()
          when 'html' then value = elem.html()
          when 'value' then value = elem.val()
          else value = elem.attr name
        return value
      # set data
      carrier = (data) ->
        # user data
        for id, attrs of model
          elem = $('#' + id)
          continue unless data[id]
          unless $.isArray attrs then set elem, attrs, data[id]
          else set elem, name, data[id][name] for name in attrs
      # post data
      data = {}
      for id, attrs of model
        elem = $('#' + id)
        data[id] = {}
        unless $.isArray attrs then data[id] = get elem, attrs
        else data[id][name] = get elem, name for name in attrs
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
    @_domain = domain.create()
    @_domain.on 'error', (err) =>
      @_finish = null
      @_error? err
    # application's event callback
    @_script = ''

  # Domain running
  domain: (callback) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_domain?.run callback

  # Catch the error
  error: (callback) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_error = callback  

  # Set headers
  set: (headers) -> @_buffer.writeHead 200, headers

  # Write chunk or pipe stream to buffer
  write: (data, encoding = 'utf8') ->
    return @_buffer.write.apply @_buffer, arguments unless data instanceof Readable
    @_buffer.on 'pipe', => @_autoend = false
    data.setEncoding = encoding
    data.pipe @_buffer, end: @_autoend
    data.on 'end', => @_buffer.end()

  # Render content
  render: -> @write 'I love starfruit!' # default      

  # Client's event script
  handle: (callback, argv) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_script += callback.script argv

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
        @handle (-> func model), func: template, model: model
      # template library
      else
        switch template
          when 'base' #, ... more templates
            @handle (-> app.core[key] model), key: template, model: model
          # default
          else @handle (-> app.core['base'] model), model: model

  # parse data raw
  parse: (raw) -> JSON.parse raw

  # Respond client
  do: (req, @_buffer) ->
    # parse url
    req.setEncoding 'utf8'
    urls = url.parse req.url
    @query = querystring.parse urls.query
    @query.raw = urls.query
    # response buffer
    @_buffer.removeAllListeners 'error'
    @_buffer.on 'error', (err) => @_error? err
    # render content
    @set "Content-Type": "text/plain;charset=utf-8"
    if !@query.raw or @query.raw.length < 1
      @_autoend = true
      @render()
    # application content
    else if @query.raw is 'script'
      @_autoend = true
      @set "Content-Type": "text/javascript;charset=utf-8"
      @write application.script()
    # geting user post data
    else
      @_autoend = false
      raw = ''
      req.on 'data', (chunk) -> raw += chunk
      req.on 'end', =>
        @data = @parse raw if raw.length > 0
        switch @query._id
          when 'event'
            selector = @query.selector
            @[selector]() if typeof @[selector] is 'function'
            switch @query._key
              when 'script'
                @set "Content-Type": "text/javascript;charset=utf-8"
                @write "app.callers['#{@query.selector}']=function(){#{@_script}};"
              when 'data'
                @set "Content-Type": "application/json;charset=utf-8"
                @write JSON.stringify @data
        @_buffer.end()
    # end respond
    @_buffer.end() if @_autoend is true
