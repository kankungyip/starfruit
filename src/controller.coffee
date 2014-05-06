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
  app.selector = window.selector = (selector) -> app _event, selector

  # set element value or attrible
  set = (elem, name, value) ->
    switch name.toString().toLowerCase()
      when 'text' then elem.text value
      when 'html' then elem.html value
      when 'value' then elem.val value
      else elem.attr name, value

  # get element value or attrible
  get = (elem, name) ->
    switch name.toString().toLowerCase()
      when 'text' then elem.text()
      when 'html' then elem.html()
      when 'value' then elem.val()
      else elem.attr name

  # core data
  app.core = {
    # base data
    base: (model) ->
      data = {}
      for id, attrs of model
        elem = $('#' + id)
        data[id] = {}
        unless $.isArray attrs then data[id] = get elem, attrs
        else data[id][name] = get elem, name for name in attrs
      $.post app._url + 'data', (JSON.stringify data), 'json'
      .done (data) ->
        for id, attrs of model
          elem = $('#' + id)
          continue unless data[id]
          unless $.isArray attrs then set elem, attrs, data[id]
          else set elem, name, data[id][name] for name in attrs
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

  # Render content
  render: ->
    template = "<!DOCTYPE html>
      <html>
        <head>
          <title>%s</title>
          <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
          <!-- Bootstrap -->
          <link rel=\"stylesheet\" href=\"http://cdn.bootcss.com/twitter-bootstrap/3.0.3/css/bootstrap.min.css\">

          <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
          <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
          <!--[if lt IE 9]>
              <script src=\"http://cdn.bootcss.com/html5shiv/3.7.0/html5shiv.min.js\"></script>
              <script src=\"http://cdn.bootcss.com/respond.js/1.3.0/respond.min.js\"></script>
          <![endif]-->

          <!-- Fav and touch icons -->
          <link rel=\"apple-touch-icon-precomposed\" sizes=\"144x144\" href=\"/apple-touch-icon-144-precomposed.png\">
          <link rel=\"apple-touch-icon-precomposed\" sizes=\"114x114\" href=\"/apple-touch-icon-114-precomposed.png\">
          <link rel=\"apple-touch-icon-precomposed\" sizes=\"72x72\" href=\"/apple-touch-icon-72-precomposed.png\">
          <link rel=\"apple-touch-icon-precomposed\" href=\"/apple-touch-icon-57-precomposed.png\">
          <link rel=\"shortcut icon\" href=\"/favicon.png\">
        </head>
        <body>
          %s

          <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
          <script src=\"http://cdn.bootcss.com/jquery/1.10.2/jquery.min.js\"></script>
          <!-- Include all compiled plugins (below), or include individual files as needed -->
          <script src=\"http://cdn.bootcss.com/twitter-bootstrap/3.0.3/js/bootstrap.min.js\"></script>
          <!-- Starfruit\'s application -->
          <script src=\"%s?script\"></script>
        </body>
      </html>"
    layout = fs.readFileSync 'res/' + @layout
    @set "Content-Type": "text/html;charset=utf-8"
    @write util.format template, @title, layout, @_pathname

  # parse data raw
  parse: (raw) -> JSON.parse raw

  # Client's event script
  handle: (callback, argv) ->
    if typeof callback isnt 'function'
      throw new TypeError typeof(callback) + ' is not a function'
    @_script += callback.script argv

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

  # Respond client
  do: (req, @_buffer) ->
    # parse url
    req.setEncoding 'utf8'
    urls = url.parse req.url
    @_pathname = urls.pathname.toLowerCase()
    @query = querystring.parse urls.query
    @query.raw = urls.query

    # response buffer
    @_buffer.removeAllListeners 'error'
    @_buffer.on 'error', (err) => @_error? err

    # render content
    if !@query.raw or @query.raw.length < 1
      @set "Content-Type": "text/plain"
      @_autoend = true
      @render()

    # application content
    else if @query.raw is 'script'
      @_autoend = true
      @set "Content-Type": "text/javascript"
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
                @set "Content-Type": "text/javascript"
                @write "app.callers['#{@query.selector}']=function(){#{@_script}};"
              when 'data'
                @set "Content-Type": "application/json"
                @write JSON.stringify @data
        @_buffer.end()

    # end respond
    @_buffer.end() if @_autoend is true
