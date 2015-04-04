Point = require "./point"
Layer = require "./layer"
Patch = require "./patch"

module.exports =
class BufferLayer extends Layer
  constructor: (@source) ->
    super
    @patch = new Patch
    @activeRegionStart = null
    @activeRegionEnd = null

  buildIterator: ->
    new BufferLayerIterator(this, @source.buildIterator(), @patch.buildIterator())

  setActiveRegion: (start, end) ->
    @activeRegionStart = start
    @activeRegionEnd = end

  contentOverlapsActiveRegion: ({column}, content) ->
    return false unless @activeRegionStart? and @activeRegionEnd?
    not (column + content.length < @activeRegionStart.column) and
      not (column > @activeRegionEnd.column)

class BufferLayerIterator
  constructor: (@layer, @sourceIterator, @patchIterator) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()

  next: ->
    comparison = @patchIterator.getPosition().compare(@position)
    if comparison <= 0
      @patchIterator.seek(@position) if comparison < 0
      next = @patchIterator.next()
      if next.value?
        @position = @patchIterator.getPosition()
        @sourcePosition = @patchIterator.getSourcePosition()
        return {value: next.value, done: next.done}

    @sourceIterator.seek(@sourcePosition)
    next = @sourceIterator.next()
    nextSourcePosition = @sourceIterator.getPosition()

    sourceOvershoot = @sourceIterator.getPosition().traversalFrom(@patchIterator.getSourcePosition())
    if sourceOvershoot.compare(Point.zero()) > 0
      next.value = next.value.substring(0, next.value.length - sourceOvershoot.column)
      nextPosition = @patchIterator.getPosition()
    else
      nextPosition = @position.traverse(nextSourcePosition.traversalFrom(@sourcePosition))

    if next.value? and @layer.contentOverlapsActiveRegion(@position, next.value)
      @patchIterator.seek(@position)
      extent = Point(0, next.value.length ? 0)
      @patchIterator.splice(extent, next.value)

    @sourcePosition = nextSourcePosition
    @position = nextPosition
    next

  seek: (@position) ->
    @patchIterator.seek(@position)
    @sourcePosition = @patchIterator.getSourcePosition()
    @sourceIterator.seek(@sourcePosition)

  getPosition: ->
    @position.copy()

  getSourcePosition: ->
    @sourcePosition.copy()

  splice: (extent, content) ->
    @patchIterator.splice(extent, content)
    @position = @patchIterator.getPosition()
    @sourcePosition = @patchIterator.getSourcePosition()
    @sourceIterator.seek(@sourcePosition)
