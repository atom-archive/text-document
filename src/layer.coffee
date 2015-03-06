{EOF, Newline} = require "./symbols"
Point = require "./point"
LayerIterator = require "./layer-iterator"

module.exports =
class Layer
  constructor: (@transform, @sourceLayer) ->
    @regions = []

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
