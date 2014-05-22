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
application = require './application'

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
  return "#{env}(#{@toString()})();"

# prototype
module.exports = class Controller

  # Constructor
  constructor: ->
    @_domain = domain.create()
    @_domain.on 'error', (err) =>
      @_finish = null
      @_error? err
    @_script = ''

  # Unique ID
  uid: (length = 8) ->
    id = ''
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  # Render content
  render: ->
    template = "<!DOCTYPE html>
      <html>
        <head>
          <title>%s</title>
          <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
          <!-- Bootstrap -->
          <link rel=\"stylesheet\" href=\"http://cdn.bootcss.com/twitter-bootstrap/3.0.3/css/bootstrap.min.css\">

          <!-- Styles -->
          <link rel=\"stylesheet\" href=\"/styles.css\">

          <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
          <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
          <!--[if lt IE 9]>
              <script src=\"http://cdn.bootcss.com/html5shiv/3.7.0/html5shiv.min.js\"></script>
              <script src=\"http://cdn.bootcss.com/respond.js/1.3.0/respond.min.js\"></script>
          <![endif]-->

          <!-- Favorite and touch icons -->
          <link rel=\"apple-touch-icon-precomposed\" sizes=\"144x144\" href=\"/apple-touch-icon-144-precomposed.png\">
          <link rel=\"apple-touch-icon-precomposed\" sizes=\"114x114\" href=\"/apple-touch-icon-114-precomposed.png\">
          <link rel=\"apple-touch-icon-precomposed\" sizes=\"72x72\" href=\"/apple-touch-icon-72-precomposed.png\">
          <link rel=\"apple-touch-icon-precomposed\" href=\"/apple-touch-icon-57-precomposed.png\">
          <link rel=\"shortcut icon\" href=\"/favicon.png\">
        </head>
        <body>
          <!-- Body contents -->
          <div class=\"container\">%s</div>

          <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
          <script src=\"http://cdn.bootcss.com/jquery/1.10.2/jquery.min.js\"></script>
          <!-- Include all compiled plugins (below), or include individual files as needed -->
          <script src=\"http://cdn.bootcss.com/twitter-bootstrap/3.0.3/js/bootstrap.min.js\"></script>
          <!-- Application's JavaScript -->
          <script src=\"%s?script\"></script>
        </body>
      </html>"
    layout = fs.readFileSync 'res/' + @layout if typeof @layout is 'string'
    layout = (fs.readFileSync 'res/' + item for item in @layout) if util.isArray @layout
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
  model: (models) ->
    return if @data
    # custom data model stored method
    stored = (sets, name) =>
      if sets.base and (sets.base.get or sets.base.set)
        name = "#{name}#{@uid()}"
        base = ''
        base += "app.models.#{name}.#{key}=#{func.toString()};" for key, func of sets.base
        @_script += "app.models.#{name}={};#{base}"
        sets.base = name
    if models.base then stored models, 'func'
    else stored sets, name for name, sets of models
    # send data model to client
    @handle (-> app.models models, selname, ctlname), models: models

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

    # load child-controller
    load = (name) =>
      dynamic = path.join process.cwd(), @server.dynamic, name
      dynamicfile = dynamic
      extname = path.extname dynamicfile
      dynamicfile = dynamicfile + '.js' if extname.length < 1
      dynamicfile = path.join dynamic, @server.default + '.js' unless fs.existsSync dynamicfile
      if fs.existsSync dynamicfile
        controller = require dynamicfile
        controller = new controller() if typeof controller is 'function'
        controller.server = @server
        error = @_error
        controller.error (err) -> error? err
        controller.init?()
      return controller

    # render content
    if !@query.raw or @query.raw.length < 1
      @_autoend = true
      @set "Content-Type": "text/plain"
      @render()

    # application content
    else if @query.raw is 'script'
      @_autoend = true
      @set "Content-Type": "text/javascript"
      @write application.script()

    # application child-layout
    else if typeof @query.layout is 'string'
      @_autoend = true
      @set "Content-Type": "text/html;charset=utf-8"
      extname = path.extname @query.layout
      layout = @query.layout + '.layout' if extname.length < 1
      @write fs.readFileSync 'res/' + layout

    # application child-controller
    else if (typeof @query.controller is 'string') and (typeof @query.selector isnt 'string')
      @_autoend = true
      controller = load @query.controller
      if typeof controller is 'object'
        @set "Content-Type": "text/html;charset=utf-8"
        @write fs.readFileSync 'res/' + controller.layout

    # application events
    else if typeof @query.selector is 'string'
      @_autoend = false
      raw = ''
      req.on 'data', (chunk) -> raw += chunk
      req.on 'end', =>
        controller = @
        controller = load @query.controller if typeof @query.controller is 'string'
        # geting user data
        controller.data = controller.parse raw if raw.length > 0
        # async data
        if controller.data
          controller.data.async = -> @_async = true
          controller.data.end = =>
            @set "Content-Type": "application/json"
            @write JSON.stringify controller.data
            @_buffer.end()
        # call event
        controller[@query.selector]() if typeof controller[@query.selector] is 'function'
        # client event's script
        unless controller.data
          @set "Content-Type": "text/javascript"
          @write "app.callers['#{@query.selector}']=function(selname, ctlname){#{controller._script}};"
          @_buffer.end()
        # data end
        controller.data.end() if controller.data and controller.data._async isnt true

    # end respond
    @_buffer.end() if @_autoend is true
