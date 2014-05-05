#
#       _/_/_/    _/                              _/_/                      _/    _/      
#    _/        _/_/_/_/    _/_/_/  _/  _/_/    _/      _/  _/_/  _/    _/      _/_/_/_/   
#     _/_/      _/      _/    _/  _/_/      _/_/_/_/  _/_/      _/    _/  _/    _/        
#        _/    _/      _/    _/  _/          _/      _/        _/    _/  _/    _/         
# _/_/_/        _/_/    _/_/_/  _/          _/      _/          _/_/_/  _/      _/_/      
#
# MIT Licensed
# Copyright (c) 2014 Kan Kung-Yip

# Module dependencies
Server = require './server'
Controller = require './controller'

# Create a application server
module.exports = ->
  server = (req, res) ->
    server.do req, res  
  server[key] = value for key, value of Server
  server.timeout = 30 # response timeout
  server.dynamic = 'lib' # dynamic contents folder
  server.static = 'pub' # static contents folder
  server.default = 'index' # default file
  return server

# Logging a message
module.exports.log = (format) ->
  throw new Error 'argv not string' if typeof format isnt 'string'
  Server.log.apply Server, arguments

# Expose the controller
module.exports.Controller = Controller
