{Emitter} = require "event-kit"
Point = require "./point"

module.exports =
class Layer
  constructor: ->
    @emitter = new Emitter

  onWillChange: (fn) ->
    @emitter.on("will-change", fn)

  onDidChange: (fn) ->
    @emitter.on("did-change", fn)

  getExtent: ->
    iterator = @buildIterator()
    loop
      break if iterator.next().done
    iterator.getPosition()

  getLines: ->
    result = []
    currentLine = ""
    iterator = @buildIterator()
    loop
      {value, done} = iterator.next()
      break if done
      currentLine += value
      if iterator.getPosition().column is 0
        result.push(currentLine)
        currentLine = ""
    result.push(currentLine)
    result

  slice: (start = Point.zero(), end = Point.infinity()) ->
    result = ""
    iterator = @buildIterator()

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

  splice: (start, extent, content) ->
    iterator = @buildIterator()
    iterator.seek(start)
    iterator.splice(extent, content)
    iterator.getPosition().traversalFrom(start)
