Point = require "../src/point"
{EOF} = require "../src/symbols"

module.exports =
class SpyLayer
  constructor: (@text, @chunkSize) ->
    @reset()

  @::[Symbol.iterator] = ->
    new Iterator(this)

  reset: ->
    @recordedReads = []

  getRecordedReads: ->
    @recordedReads

class Iterator
  constructor: (@layer) ->
    @position = Point.zero()

  next: ->
    value = @layer.text.substr(@position.column, @layer.chunkSize) or EOF
    @position.column += @layer.chunkSize
    @layer.recordedReads.push(value)
    {value, done: value is EOF}

  seek: (position) ->
    @position = position.copy()

  getPosition: ->
    @position
