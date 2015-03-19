Layer = require "../src/layer"
Point = require "../src/point"

module.exports =
class SpyLayer extends Layer
  constructor: (@text, @chunkSize) ->
    super
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
    if value = @layer.text.substr(@position.column, @layer.chunkSize)
      @position.column += value.length
      done = false
    else
      value = undefined
      done = true
    @layer.recordedReads.push(value)
    {value, done}

  seek: (position) ->
    @position = position.copy()

  getPosition: ->
    @position.copy()
