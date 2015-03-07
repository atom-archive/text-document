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
  constructor: (@store) ->
    @position = 0

  next: ->
    previousPosition = @position
    @position += @chunkSize
    value = @store.text.substr(previousPosition, @store.chunkSize) or null
    @store.recordedReads.push(value)
    if value
      {done: false, value}
    else
      {done: true}

  seek: (@position) ->

  getPosition: ->
    @position
