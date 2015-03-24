Patch = require "./patch"
Layer = require "./layer"
Point = require "./point"

module.exports =
class MutationLayer extends Layer
  constructor: (@source) ->
    super
    @mutatedContent = new Patch

  buildIterator: ->
    new Iterator(this, @source.buildIterator(), @mutatedContent.buildIterator())

class Iterator
  constructor: (@layer, @sourceIterator, @mutatedContentIterator) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()

  next: ->
    comparison = @mutatedContentIterator.getPosition().compare(@position)
    if comparison <= 0
      @mutatedContentIterator.seek(@position) if comparison < 0
      next = @mutatedContentIterator.next()
      if next.value?
        @position = @mutatedContentIterator.getPosition()
        @sourcePosition = @mutatedContentIterator.getSourcePosition()
        return {value: next.value, done: next.done}

    @sourceIterator.seek(@sourcePosition)
    next = @sourceIterator.next()
    nextSourcePosition = @sourceIterator.getPosition()

    sourceOvershoot = @sourceIterator.getPosition().traversalFrom(@mutatedContentIterator.getSourcePosition())
    if sourceOvershoot.compare(Point.zero()) > 0
      next.value = next.value.substring(0, next.value.length - sourceOvershoot.column)
      nextPosition = @mutatedContentIterator.getPosition()
    else
      nextPosition = @position.traverse(nextSourcePosition.traversalFrom(@sourcePosition))

    @sourcePosition = nextSourcePosition
    @position = nextPosition
    next

  seek: (@position) ->
    @mutatedContentIterator.seek(@position)
    @sourcePosition = @mutatedContentIterator.getSourcePosition()
    @sourceIterator.seek(@sourcePosition)

  getPosition: ->
    @position.copy()

  splice: (extent, content) ->
    @mutatedContentIterator.seek(@position)
    @mutatedContentIterator.splice(extent, content)
