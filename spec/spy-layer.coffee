Layer = require "../src/layer"
Point = require "../src/point"

module.exports =
class SpyLayer extends Layer
  constructor: (@inputLayer) ->
    super
    @reset()

  buildIterator: ->
    new SpyLayerIterator(this, @inputLayer.buildIterator())

  reset: -> @recordedReads = []
  getRecordedReads: -> @recordedReads

class SpyLayerIterator
  constructor: (@layer, @iterator) ->

  next: ->
    next = @iterator.next()
    @layer.recordedReads.push(next.value)
    next

  seek: (position) -> @iterator.seek(position)
  getPosition: -> @iterator.getPosition()
