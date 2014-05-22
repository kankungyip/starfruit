{Controller} = require '../../'

module.exports = class App extends Controller

  init: ->
    @layout = 'hello.layout'

  timeClick: ->
    @model
      time: ['text', 'style']
    return unless @data
    @data.async()
    setTimeout (=>
      @data.time.text = new Date().toString()
      @data.time.style = 'color:blue'
      @data.end()
    ), 5000

  helloClick: ->
    @model
      username: 'value'
      message: 'text'
    return unless @data
    @data.message = "Hello #{@data.username}, Welcome to Starfruit World!" if @data.username
    