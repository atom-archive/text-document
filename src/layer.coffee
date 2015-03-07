{Emitter} = require "event-kit"
{Newline} = require "./symbols"
Point = require "./point"
LayerIterator = require "./layer-iterator"

module.exports =
class Layer
  pendingChangeOldExtent: null

  constructor: (@transform, @sourceLayer) ->
    @emitter = new Emitter
    @sourceLayer.onWillChange(@sourceLayerWillChange)
    @sourceLayer.onDidChange(@sourceLayerDidChange)

  getLines: ->
    result = []
    currentLine = ""
    iterator = @[Symbol.iterator]()
    loop
      {value, done} = iterator.next()
      break if done
      if value is Newline
        result.push(currentLine)
        currentLine = ""
      else
        currentLine += value
    result.push(currentLine)
    result

  slice: (start, end) ->
    result = ""
    iterator = @[Symbol.iterator]()

    iterator.seek(start)
    loop
      {value, done} = iterator.next()
      break if done
      continue if value is Newline
      if iterator.getPosition().compare(end) <= 0
        result += value
      else
        overshoot = iterator.getPosition().column - end.column
        result += value.slice(0, value.length - overshoot)
        break
    result

  @::[Symbol.iterator] = ->
    new LayerIterator(this, @sourceLayer[Symbol.iterator]())

  onDidChange: (fn) ->
    @emitter.on("did-change", fn)

  sourceLayerWillChange: ({position, oldExtent}) =>
    iterator = @[Symbol.iterator]()
    iterator.seekToSourcePosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToSourcePosition(position.traverse(oldExtent))
    @pendingChangeOldExtent = iterator.getPosition().traversalFrom(startPosition)

  sourceLayerDidChange: ({position, newExtent}) =>
    iterator = @[Symbol.iterator]()
    iterator.seekToSourcePosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToSourcePosition(position.traverse(newExtent))

    oldExtent = @pendingChangeOldExtent
    newExtent = iterator.getPosition().traversalFrom(startPosition)
    @pendingChangeOldExtent = null

    @emitter.emit "did-change", {position: startPosition, oldExtent, newExtent}
