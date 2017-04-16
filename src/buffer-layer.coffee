Point = require "./point"
Layer = require "./layer"
Patch = require "./patch"

module.exports =
class BufferLayer extends Layer
  constructor: (@inputLayer) ->
    super
    @patch = new Patch
    @activeRegionStart = null
    @activeRegionEnd = null

  buildIterator: ->
    new BufferLayerIterator(this, @inputLayer.buildIterator(), @patch.buildIterator())

  setActiveRegion: (@activeRegionStart, @activeRegionEnd) ->

  contentOverlapsActiveRegion: ({column}, content) ->
    (@activeRegionStart? and @activeRegionEnd?) and
      (column + content.length >= @activeRegionStart.column) and
      (column <= @activeRegionEnd.column)

class BufferLayerIterator
  constructor: (@layer, @inputIterator, @patchIterator) ->
    @position = Point.zero()
    @inputPosition = Point.zero()

  next: ->
    comparison = @patchIterator.getOutputPosition().compare(@position)
    if comparison <= 0
      @patchIterator.seek(@position) if comparison < 0
      next = @patchIterator.next()
      if next.value?
        @position = @patchIterator.getOutputPosition()
        @inputPosition = @patchIterator.getInputPosition()
        return next

    @inputIterator.seek(@inputPosition)
    next = @inputIterator.next()
    nextInputPosition = @inputIterator.getPosition()

    inputOvershoot = @inputIterator.getPosition().traversalFrom(@patchIterator.getInputPosition())
    if inputOvershoot.isPositive()
      next.value = next.value.slice(0, next.value.length - inputOvershoot.column) if next.value
      nextPosition = @patchIterator.getOutputPosition()
    else
      nextPosition = @position.traverse(nextInputPosition.traversalFrom(@inputPosition))

    if next.value? and @layer.contentOverlapsActiveRegion(@position, next.value)
      @patchIterator.seek(@position)
      extent = Point(0, next.value.length ? 0)
      @patchIterator.splice(extent, Point(0, next.value.length), next.value)

    @inputPosition = nextInputPosition
    @position = nextPosition
    next

  seek: (@position) ->
    @patchIterator.seek(@position)
    @inputPosition = @patchIterator.getInputPosition()
    @inputIterator.seek(@inputPosition)

  getPosition: ->
    @position.copy()

  getInputPosition: ->
    @inputPosition.copy()

  splice: (extent, content) ->
    @patchIterator.splice(extent, Point(0, content.length), content)
    @position = @patchIterator.getOutputPosition()
    @inputPosition = @patchIterator.getInputPosition()
    @inputIterator.seek(@inputPosition)
