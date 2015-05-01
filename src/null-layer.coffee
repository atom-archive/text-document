Point = require "./point"

module.exports =
class NullLayer
  buildIterator: ->
    new NullLayerIterator

class NullLayerIterator
  next: -> {value: null, done: true}
  seek: ->
  getPosition: -> Point.zero()
