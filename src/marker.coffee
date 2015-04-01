{Emitter} = require "event-kit"

module.exports =
class Marker
  constructor: (@id, @manager, @properties) ->
    @emitter = new Emitter

  getRange: -> @manager.getMarkerRange(@id)

  getHeadPosition: -> @manager.getMarkerStartPosition(@id)

  getTailPosition: -> @manager.getMarkerEndPosition(@id)

  setHeadPosition: ->

  setTailPosition: ->

  isValid: -> true

  matchesParams: (params) ->
    for key, value of params
      return false unless @properties[key] is value
    true

  getProperties: -> @properties

  setProperties: (newProperties) ->
    for key, value of newProperties
      @properties[key] = value

  isReversed: -> false

  hasTail: -> false

  clearTail: ->

  plantTail: ->

  destroy: ->
    @manager.destroyMarker(@id)
    @emitter.emit("did-destroy")

  ###
  Section: Event Subscription
  ###

  onDidDestroy: (callback) ->
    @emitter.on("did-destroy", callback)

  onDidChange: (callback) ->
    @emitter.on("did-change", callback)
