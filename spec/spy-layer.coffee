Point = require "../src/point"

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
    value = @layer.text.substr(@position.column, @layer.chunkSize) or null
    @position.column += @layer.chunkSize
    @layer.recordedReads.push(value)
    if value
      {done: false, value}
    else
      {done: true}

  seek: (position) ->
    @position = position.copy()

  getPosition: ->
    @position
