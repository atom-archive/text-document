{Emitter} = require "event-kit"
Point = require "./point"
TransformIterator = require "./transform-iterator"

module.exports =
class TransformLayer
  pendingChangeOldExtent: null

  constructor: (@sourceLayer, @transform) ->
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
      currentLine += value
      if iterator.getPosition().column is 0
        result.push(currentLine)
        currentLine = ""
    result.push(currentLine)
    result

  slice: (start, end) ->
    result = ""
    iterator = @[Symbol.iterator]()

    lastPosition = start
    iterator.seek(start)

    loop
      {value, done} = iterator.next()
      break if done
      if iterator.getPosition().compare(end) <= 0
        result += value
      else
        result += value.slice(0, end.traversalFrom(lastPosition).column)
        break
      lastPosition = iterator.getPosition()
    result

  @::[Symbol.iterator] = ->
    new TransformIterator(this, @sourceLayer[Symbol.iterator]())

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
