{Emitter} = require "event-kit"

module.exports =
class Marker
  constructor: (@id, @range, @properties) ->
    @emitter = new Emitter

  getRange: -> @range

  getHeadPosition: -> @range.start

  getTailPosition: -> @range.end

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

  ###
  Section: Event Subscription
  ###

  onDidDestroy: (callback) ->
    @emitter.on("did-destroy", callback)

  onDidChange: (callback) ->
    @emitter.on("did-change", callback)
