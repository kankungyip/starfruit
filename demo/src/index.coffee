fs = require 'fs'
{Controller} = require '../../'

module.exports = class App extends Controller

  init: ->
    @title = 'layout'
    @layout = 'app.layout'

  timeClick: ->
    @model
      time: ["text", "style"]
    return unless @data
    @data.time.text = new Date().toString()
    @data.time.style = 'color:blue'

  helloClick: ->
    @model
      username: "value"
      message: "text"
    return unless @data
    @data.message = "Hello #{@data.username}, welcome to starfruit world!" if @data.username
