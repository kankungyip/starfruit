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
path = require 'path'
util = require 'util'
domain = require 'domain'
cluster = require 'cluster'
{Transform} = require 'stream'

# prototype
module.exports = class Controller

  # Default init
  _init: (app) ->
    app.statusCode = 200
    app.contentType = 'text/html'
    app.charset = 'utf-8'

    # build error
    error = (err) ->
      err.charset = app.charset
      return err

    # buffer
    app._buffer = new Transform()
    app._buffer._transform = (chunk, encoding, callback) ->
      @push chunk, encoding
      callback()
    app._buffer.on 'finish', ->
      app._finish? app.statusCode, app.contentType, app.charset
    app._buffer.on 'error', (err) ->
      app._error? error err

    # sandbox
    app._sandbox = domain.create()
    app._sandbox.on 'error', (err) ->
      app._finish = null
      app._error? error err

  # Constructor
  constructor: ->
    @_init @

  # Buffer end method
  end: ->
    @_buffer?.end()

  # Buffer push method
  push: (chunk) ->
    @_buffer?.end() if !chunk
    @_buffer?.push.apply @_buffer, arguments

  # Buffer 
  pipe: ->
    @_buffer?.pipe.apply @_buffer, arguments

  # Receive stream date
  receive: (stream, encoding = 'utf8') ->
    stream.setEncoding = encoding if typeof encoding is 'string'
    stream?.pipe @_buffer if @_buffer

  # Sandbox runing
  sandbox: (callback) ->
    if typeof callback isnt 'function'
      msg = typeof(callback) + ' is not a function'
      err = new TypeError msg
      throw err
    @_sandbox?.run callback

  # Catch the error
  error: (callback) ->
    if typeof callback isnt 'function'
      msg = typeof(callback) + ' is not a function'
      err = new TypeError msg
      throw err
    @_error = callback

  # Finish contorl
  finish: (callback) ->
    if typeof callback isnt 'function'
      msg = typeof(callback) + ' is not a function'
      err = new TypeError msg
      throw err
    @_finish = callback
