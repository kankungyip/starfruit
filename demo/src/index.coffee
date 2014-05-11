fs = require 'fs'
{Controller} = require '../../'

module.exports = class App extends Controller

  init: ->
    @title = 'layout'
    @layout = 'app.layout'

    @listModel =
      base: 'list',
      root: 'listGroup'
      entry:
        title: 'text'
        text: 'text'
      active:
        class: 'active'

  timeClick: ->
    @model
      time: ['text', 'style']
    return unless @data
    @data.time.text = new Date().toString()
    @data.time.style = 'color:blue'

  helloClick: ->
    @model
      username: 'value'
      message: 'text'
    return unless @data
    @data.message = "Hello #{@data.username}, Welcome to Starfruit World!" if @data.username

  listLoad: ->
    @listModel.method = 'add'
    @model @listModel
    return unless @data
    for i in [1..5]
      id = @uid()
      @data[id] ?= {}
      @data[id]['title'] = 'List item heading'
      @data[id]['text'] = 'The ID is: ' + id

  itemAdd: ->
    @listModel.method = 'add'
    @model @listModel
    return unless @data
    id = @uid()
    @data[id] ?= {}
    @data[id]['title'] = 'Add item heading'
    @data[id]['text'] = 'The ID is: ' + id

  itemInsert: ->
    @listModel.method = 'insert'
    @model @listModel
    return unless @data
    id = @uid()
    @data[id] ?= {}
    @data[id]['title'] = 'Insert item heading'
    @data[id]['text'] = 'The ID is: ' + id

  listBlur: ->
    @listModel.method = 'blur'
    @model
      list: @listModel
      others:
        insertItem: 'style'
        deleteItem: 'style'
        cancelItem: 'style'
        listState: 'text'
    return unless @data
    @data.others.insertItem = 'display:none'
    @data.others.deleteItem = 'display:none'
    @data.others.cancelItem = 'display:none'
    @data.others.listState = ''

  itemActive: ->
    @listModel.method = 'active'
    @listModel.active.index = 0
    @model
      list: @listModel
      others:
        insertItem: 'style'
        deleteItem: 'style'
        cancelItem: 'style'
        listState: 'text'
    return unless @data
    @data.others.insertItem = 'display:'
    @data.others.deleteItem = 'display:'
    @data.others.cancelItem = 'display:'
    @data.others.listState = 'Selected ID: ' + @data.list._id

  itemClick: ->
    @listModel.method = 'active'
    @model
      list: @listModel
      others:
        insertItem: 'style'
        deleteItem: 'style'
        cancelItem: 'style'
        listState: 'text'
    return unless @data
    @data.others.insertItem = 'display:'
    @data.others.deleteItem = 'display:'
    @data.others.cancelItem = 'display:'
    @data.others.listState = 'Selected ID: ' + @data.list._id

  itemRemove: ->
    @listModel.method = 'remove'
    @model
      list: @listModel
      others:
        insertItem: 'style'
        deleteItem: 'style'
        cancelItem: 'style'
        listState: 'text'
    return unless @data
    @data.others.insertItem = 'display:none'
    @data.others.deleteItem = 'display:none'
    @data.others.cancelItem = 'display:none'
    @data.others.listState = 'Removed ID: ' + @data.list._id
