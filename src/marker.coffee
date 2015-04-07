Point = require "./point"
Range = require "./range"
{Emitter} = require "event-kit"

module.exports =
class Marker
  constructor: (@id, @manager, @properties) ->
    @emitter = new Emitter
    @reversed = false
    @valid = true
    @tailed = true

    if @properties.reversed
      @reversed = @properties.reversed
      delete @properties.reversed
    if @properties.invalidate
      @invalidationStrategy = @properties.invalidate
      delete @properties.invalidate

  getRange: ->
    @manager.getMarkerRange(@id)

  getHeadPosition: ->
    if @reversed
      @manager.getMarkerStartPosition(@id)
    else
      @manager.getMarkerEndPosition(@id)

  getTailPosition: ->
    if @reversed
      @manager.getMarkerEndPosition(@id)
    else
      @manager.getMarkerStartPosition(@id)

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

  update: ({reversed, tailed, headPosition, tailPosition, range, properties}) ->
    changed = false
    wasValid = @valid
    hadTail = @tailed
    oldProperties = clone(@properties)

    newRange = oldRange = @getRange()
    if @reversed
      newHeadPosition = oldHeadPosition = oldRange.start
      newTailPosition = oldTailPosition = oldRange.end
    else
      newHeadPosition = oldHeadPosition = oldRange.end
      newTailPosition = oldTailPosition = oldRange.start

    if reversed? and reversed isnt @reversed
      @reversed = reversed
      changed = true

    if tailed? and tailed isnt @tailed
      @tailed = tailed
      unless @tailed
        @reversed = false
        newTailPosition = oldHeadPosition
        newRange = Range(oldHeadPosition, oldHeadPosition)
      changed = true

    if range? and not range.isEqual(oldRange)
      newRange = range
      if @reversed
        newHeadPosition = range.start
        newTailPosition = range.end
      else
        newHeadPosition = range.end
        newTailPosition = range.start
      changed = true

    if headPosition? and not headPosition.isEqual(oldHeadPosition)
      newHeadPosition = headPosition
      if not @tailed
        newTailPosition = headPosition
        newRange = Range(headPosition, headPosition)
      else if headPosition.compare(oldTailPosition) < 0
        @reversed = true
        newRange = Range(headPosition, oldTailPosition)
      else
        @reversed = false
        newRange = Range(oldTailPosition, headPosition)
      changed = true

    if tailPosition? and not tailPosition.isEqual(oldTailPosition)
      @tailed = true
      newTailPosition = tailPosition
      if tailPosition.compare(oldHeadPosition) < 0
        @reversed = false
        newRange = Range(tailPosition, oldHeadPosition)
      else
        @reversed = true
        newRange = Range(oldHeadPosition, tailPosition)
      changed = true

    if properties? and not @matchesParams(properties)
      @setProperties(properties)
      changed = true

    if changed
      @manager.setMarkerRange(@id, newRange)
      @emitter.emit("did-change", {
        wasValid, isValid: @valid
        hadTail, hasTail: @tailed
        oldProperties, newProperties: clone(@properties)
        oldHeadPosition, newHeadPosition
        oldTailPosition, newTailPosition
        textChanged: false
      })
      true
    else
      false

  isValid: -> true

  matchesParams: (params) ->
    for key, value of params
      if key is 'invalidate'
        return false unless @invalidationStrategy is value
      else
        return false unless @properties[key] is value
    true

  getProperties: -> @properties

  setProperties: (newProperties) ->
    for key, value of newProperties
      @properties[key] = value

  compare: (other) ->
    @getRange().compare(other.getRange())

  isReversed: -> @reversed

  hasTail: -> @tailed

  destroy: ->
    @manager.destroyMarker(@id)
    @emitter.emit("did-destroy")

  copy: ->
    @manager.markRange(@getRange(), clone(@properties))

  ###
  Section: Event Subscription
  ###

  onDidDestroy: (callback) ->
    @emitter.on("did-destroy", callback)

  onDidChange: (callback) ->
    @emitter.on("did-change", callback)

  toString: ->
    "[Marker #{@id}, #{@getRange()}]"

clone = (object) ->
  result = {}
  result[key] = value for key, value of object
  result
