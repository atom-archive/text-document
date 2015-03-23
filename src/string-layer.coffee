Point = require "./point"
Layer = require "./layer"

module.exports =
class StringLayer extends Layer
  constructor: (@content) ->
    super

  buildIterator: ->
    new Iterator(this)

class Iterator
  constructor: (@layer) ->
    @seek(Point.zero())

  next: ->
    result = if @position.column >= @layer.content.length
      {value: undefined, done: true}
    else
      {value: @layer.content.substring(@position.column), done: false}
    @position = Point(0, @layer.content.length)
    result

  seek: (@position) ->
    @assertValidPosition(@position)

  getPosition: ->
    @position.copy()

  splice: (oldExtent, content) ->
    @assertValidPosition(@position.traverse(oldExtent))

    @layer.emitter.emit("will-change", {@position, oldExtent})

    @layer.content =
      @layer.content.substring(0, @position.column) +
      content +
      @layer.content.substring(@position.column + oldExtent.column)

    @layer.emitter.emit("did-change", {@position, oldExtent, newExtent: Point(0, content.length)})

  assertValidPosition: (position) ->
    unless position.row is 0 and 0 <= position.column <= @layer.content.length
      throw new Error("Invalid position #{position}")
