Point = require "./point"
Range = require "./range"
{Emitter} = require "event-kit"

module.exports =
class Marker
  constructor: (@id, @store, range, @properties) ->
    @emitter = new Emitter
    @valid = true

    @tailed = @properties.tailed ? true
    delete @properties.tailed

    @reversed = @properties.reversed ? false
    delete @properties.reversed

    @invalidationStrategy = @properties.invalidate ? 'overlap'
    delete @properties.invalidate

    @store.setMarkerHasTail(@id, @tailed)
    @previousEventState = @getEventState(range)

  getRange: ->
    @store.getMarkerRange(@id)

  getHeadPosition: ->
    if @reversed
      @store.getMarkerStartPosition(@id)
    else
      @store.getMarkerEndPosition(@id)

  getTailPosition: ->
    if @reversed
      @store.getMarkerEndPosition(@id)
    else
      @store.getMarkerStartPosition(@id)

  setRange: (range, properties) ->
    if properties?.reversed?
      reversed = properties.reversed
      delete properties.reversed
    @update({range: Range.fromObject(range), tailed: true, reversed, properties})

  setHeadPosition: (position, properties) ->
    @update({headPosition: Point.fromObject(position), properties})

  setTailPosition: (position, properties) ->
    @update({tailPosition: Point.fromObject(position), properties})

  clearTail: ->
    @update({tailed: false})

  plantTail: ->
    @update({tailed: true})

  getInvalidationStrategy: -> @invalidationStrategy

  getProperties: -> @properties

  setProperties: (newProperties) ->
    for key, value of newProperties
      @properties[key] = value

  update: ({reversed, tailed, valid, headPosition, tailPosition, range, properties}, textChanged=false) ->
    changed = propertiesChanged = false

    wasTailed = @tailed
    newRange = oldRange = @getRange()
    if @reversed
      oldHeadPosition = oldRange.start
      oldTailPosition = oldRange.end
    else
      oldHeadPosition = oldRange.end
      oldTailPosition = oldRange.start

    if reversed? and reversed isnt @reversed
      @reversed = reversed
      changed = true

    if valid? and valid isnt @valid
      @valid = valid
      changed = true

    if tailed? and tailed isnt @tailed
      @tailed = tailed
      changed = true
      unless @tailed
        @reversed = false
        newRange = Range(oldHeadPosition, oldHeadPosition)

    if properties? and not @matchesParams(properties)
      @setProperties(properties)
      changed = true
      propertiesChanged = true

    if range?
      newRange = range

    if headPosition? and not headPosition.isEqual(oldHeadPosition)
      changed = true
      if not @tailed
        newRange = Range(headPosition, headPosition)
      else if headPosition.compare(oldTailPosition) < 0
        @reversed = true
        newRange = Range(headPosition, oldTailPosition)
      else
        @reversed = false
        newRange = Range(oldTailPosition, headPosition)

    if tailPosition? and not tailPosition.isEqual(oldTailPosition)
      changed = true
      @tailed = true
      if tailPosition.compare(oldHeadPosition) < 0
        @reversed = false
        newRange = Range(tailPosition, oldHeadPosition)
      else
        @reversed = true
        newRange = Range(oldHeadPosition, tailPosition)
      changed = true

    unless newRange.isEqual(oldRange)
      @store.setMarkerRange(@id, newRange)
    unless @tailed is wasTailed
      @store.setMarkerHasTail(@id, @tailed)
    @emitChangeEvent(newRange, textChanged, propertiesChanged)
    changed

  emitChangeEvent: (currentRange, textChanged, propertiesChanged) ->
    oldState = @previousEventState
    newState = @previousEventState = @getEventState(currentRange)

    return unless propertiesChanged or
      oldState.valid isnt newState.valid or
      oldState.tailed isnt newState.tailed or
      oldState.headPosition.compare(newState.headPosition) isnt 0 or
      oldState.tailPosition.compare(newState.tailPosition) isnt 0

    @emitter.emit("did-change", {
      wasValid: oldState.valid, isValid: newState.valid
      hadTail: oldState.tailed, hasTail: newState.tailed
      oldProperties: oldState.properties, newProperties: newState.properties
      oldHeadPosition: oldState.headPosition, newHeadPosition: newState.headPosition
      oldTailPosition: oldState.tailPosition, newTailPosition: newState.tailPosition
      textChanged: textChanged
    })

  isValid: -> @valid

  matchesParams: (params) ->
    for key, value of params
      if key is 'invalidate'
        return false unless @invalidationStrategy is value
      else
        return false unless @properties[key] is value
    true

  compare: (other) ->
    @getRange().compare(other.getRange())

  isReversed: -> @reversed

  hasTail: -> @tailed

  destroy: ->
    @store.destroyMarker(@id)
    @emitter.emit("did-destroy")

  copy: (options) ->
    properties = clone(@properties)
    properties[key] = value for key, value of options
    @store.markRange(@getRange(), options)

  ###
  Section: Event Subscription
  ###

  onDidDestroy: (callback) ->
    @emitter.on("did-destroy", callback)

  onDidChange: (callback) ->
    @emitter.on("did-change", callback)

  toString: ->
    "[Marker #{@id}, #{@getRange()}]"

  ###
  Section: Private
  ###

  getEventState: (range) ->
    {
      headPosition: (if @reversed then range.start else range.end)
      tailPosition: (if @reversed then range.end else range.start)
      properties: clone(@properties)
      tailed: @tailed
      valid: true
    }

clone = (object) ->
  result = {}
  result[key] = value for key, value of object
  result
