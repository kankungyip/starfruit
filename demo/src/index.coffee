{Controller} = require '../../'

module.exports = class App extends Controller

  init: ->
    @title = 'Hello World!'
    @layout = 'app.layout'

    @listModel =
      base: 'list',
      root: 'listGroup'
      entry:
        title: 'text'
        text: 'text'
      active:
        class: 'active'

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
