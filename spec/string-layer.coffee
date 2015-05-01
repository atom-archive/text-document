Point = require "../src/point"
Layer = require "../src/layer"

module.exports =
class StringLayer extends Layer
  constructor: (@content, @chunkSize=@content.length) ->
    super

  buildIterator: ->
    new StringLayerIterator(this)

class StringLayerIterator
  constructor: (@layer) ->
    @position = Point.zero()

  next: ->
    if @position.column >= @layer.content.length
      return {value: undefined, done: true}
    else
      startColumn = @position.column
      @position = Point(0, Math.min(startColumn + @layer.chunkSize, @layer.content.length))
      {value: @layer.content.slice(startColumn, @position.column), done: false}

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

    change = Object.freeze({@position, oldExtent, newExtent: Point(0, content.length)})
    @position = @position.traverse(Point(0, content.length))
    @layer.emitter.emit("did-change", change)

  assertValidPosition: (position) ->
    unless position.row is 0 and 0 <= position.column <= @layer.content.length
      throw new Error("Invalid position #{position}")
