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
# Application script

# prototype
module.exports = ->
  
  # application object
  app = window.app = {}
  app.callers = {}
  app.serial = 0

  # heartbeat radio
  app.radio = ->

  # application events
  app.selector = window.selector = (selname) ->
    url = "#{location.pathname}?selector=#{selname}"
    window._event = event
    target = $ event.target
    root = target.parents "[onload*='controller']:first"
    if root.length > 0
      tmp = /[\'\"]+(\w*)[\'\"]+/.exec root.attr 'onload'
      ctlname = tmp[1].toString().trim() if tmp and tmp.length > 1
      url += "&controller=#{ctlname}" if ctlname
    return app.callers[selname](selname, ctlname) if typeof app.callers[selname] is 'function'
    $.getScript url
    .done -> app.callers[selname](selname, ctlname) if typeof app.callers[selname] is 'function'

  # application child-controller
  app.controller = window.controller = (ctlname) ->
    target = $ "[onload*='controller'][onload*='#{ctlname}']"
    $.get "#{location.pathname}?controller=#{ctlname}"
    .done (data) ->
      target.html data
      target.find('[onload]').load()

  # application child-layout
  app.layout = window.layout = (layname) ->
    target = $ "[onload*='layout'][onload*='#{layname}']"
    $.get "#{location.pathname}?layout=#{layname}"
    .done (data) ->
      target.html data
      target.find('[onload]').load()

  # get element value or attrible
  getValue = app.getValue = (elem, name) ->
    switch name.toString().toLowerCase()
      when 'text' then elem.text()
      when 'html' then elem.html()
      when 'value' then elem.val()
      else elem.attr name

  # set element value or attrible
  setValue = app.setValue = (elem, name, value) ->
    switch name.toString().toLowerCase()
      when 'text' then elem.text value
      when 'html' then elem.html value
      when 'value' then elem.val value
      else elem.attr name, value

  # data model
  models = app.models = (model, selname, ctlname) ->
    # getting data
    get = ->
      data = {}
      _get = (sets) ->
        sets._selname = selname
        sets.base ?= 'base'
        if (models[sets.base]?) and (typeof models[sets.base].get is 'function')
          models[sets.base].get sets
        else models.base.get sets, $('html')
      for name, sets of model
        if (typeof sets is 'string') or $.isArray sets
          data = _get model
          break
        data[name] = _get sets
      JSON.stringify data

    # setting data
    set = (data) ->
      _set = (sets, data) ->
        sets._selname = selname
        sets.base ?= 'base'
        if (models[sets.base]?) and (typeof models[sets.base].get is 'function')
          models[sets.base].set sets, data
        else models.base.set sets, data, $('html')
      for name, sets of model
        if (typeof sets is 'string') or $.isArray sets
          _set model, data
          break
        _set sets, data[name]

    # post event
    url = "#{location.pathname}?selector=#{selname}"
    url += "&controller=#{ctlname}" if ctlname
    $.post url, get(), set, 'json'

  # base data model
  models.base =
    get: (sets, root) ->
      root ?= $('html')
      data = {}
      sets = sets.entry if sets.entry
      for id, attrs of sets
        elem = root.find '#' + id
        data[id] = {}
        unless $.isArray attrs then data[id] = getValue elem, attrs
        else data[id][attr] = getValue elem, attr for attr in attrs
      return data

    set: (sets, data, root) ->
      root ?= $('html')
      sets = sets.entry if sets.entry
      for id, attrs of sets
        elem = root.find '#' + id
        continue unless data[id]?
        unless $.isArray attrs then setValue elem, attrs, data[id]
        else setValue elem, attr, data[id][attr] for attr in attrs

  # list data model
  models.list =
    actived: (sets) ->
      root = $ '#' + sets.root
      temp = "[style*='#{sets.active.style}']"
      temp = ".#{sets.active.class}" if sets.active.class
      root.children temp

    target: (sets) ->
      if sets.active.index?
        root = $ '#' + sets.root
        index = parseInt sets.active.index
        if isNaN(index) or (index < 0) then index = 0
        length = root.children().length
        if index >= length then index = length - 1
        target = root.children().eq index
      else
        target = $ _event.target
        type = 'on' + _event.type
        if typeof target.attr(type) isnt 'string'
          target = target.parents "[#{type}*='#{sets._selname}']:first"
      return target

    get: (sets) ->
      data = {}
      actived = models.list.actived sets
      switch sets.method.toLowerCase()
        when 'remove'
          data = models.base.get sets.entry, actived
          data._id = actived.attr 'id'
        when 'active'
          target = actived
          target = models.list.target sets unless sets.active.index? and actived.length > 0
          data = models.base.get sets.entry, target
          data._id = target.attr 'id'
      return data

    set: (sets, data) ->
      actived = models.list.actived sets
      method = sets.method.toLowerCase()
      switch method
        when 'add', 'insert'
          return unless data
          root = $ '#' + sets.root
          return if root.length < 1
          temp = "[style*='#{sets.active.style}']"
          temp = ".#{sets.active.class}" if sets.active.class
          template = root.children().not(temp).first()
          for uid, record of data
            entry = template.clone()
            entry.attr 'id', uid
            # set contents
            for id, attrs of sets.entry
              elem = entry.children '#' + id
              unless $.isArray attrs then setValue elem, attrs, record[id]
              else setValue elem, attr, value[id][attr] for attr in attrs
            if (actived.index() < 0) or (method is 'add') then root.append entry
            else entry.insertBefore actived
          unless template.attr('id') then template.remove()

        when 'active'
          return if sets.active.index? and actived.length > 0
          root = $ '#' + sets.root
          target = models.list.target sets
          models.base.set sets, data, target
          # active style
          if sets.active.class
            root.children().removeClass sets.active.class
            target.addClass sets.active.class
          if sets.active.style
            template = root.children().not("[style*='#{sets.active.style}']").first()
            style = if template.attr 'style' then template.attr 'style' else ''
            root.children().attr 'style', style
            style = if target.attr 'style' then target.attr 'style' else ''
            target.attr 'style', "#{style};#{sets.active.style};"

        when 'blur', 'remove'
          root = $ '#' + sets.root
          if sets.active.class
            root.children().removeClass sets.active.class
          if sets.active.style
            template = root.children().not("[style*='#{sets.active.style}']").first()
            style = if template.attr 'style' then template.attr 'style' else ''
            root.children().attr 'style', style
          # remove actived item
          actived.remove() if (method is 'remove') and (actived.index() > -1)

  # getting user event
  window.constructor::__defineGetter__ 'event', ->
    func = arguments.callee.caller
    while func?
      arg = func.arguments[0]
      return arg if arg instanceof Event
      func = func.caller
    return null

  # elements' load event
  $(document).ready -> $('[onload]').load()
