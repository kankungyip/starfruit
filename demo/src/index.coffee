fs = require 'fs'
{Controller} = require '../../'

module.exports = class App extends Controller

  render: ->
    @domain =>
      @set "Content-Type": "text/html;charset=utf-8"
      @write fs.createReadStream 'res/app.html'

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
    @data.message = "hello #{@data.username}, welcome to starfruit world." if @data.username
