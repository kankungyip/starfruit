# Starfruit
#
# MIT Licensed
#
# Copyright (c) 2014 Kan Kung-Yip

# Module dependencies
Server = require './server'

# Create a new connect server
createServer = ->
  app = (req, res) ->
    app.respond req, res  
  app[key] = value for key, value of Server
  app.timeout = 30 # response timeout
  app.static = 'pub' # static contents folder
  app.index = 'index.html' # default index file
  return app

# Expose createServer() as the module
module.exports = createServer

# Logging a message
log = (format) ->
  throw new Error 'argv not string' if typeof format isnt 'string'
  Server.log.apply Server, arguments

# Expose the logger
module.exports.log = log

# Logging a debug information
debug = (format) ->
  throw new Error 'argv not string' if typeof format isnt 'string'
  Server.debug.apply Server, arguments

# Expose the debug logger
module.exports.debug = debug
