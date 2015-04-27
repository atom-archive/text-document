Point = require "./point"

module.exports =
class Range
  @fromObject: (object) ->
    if object instanceof Range
      object
    else
      if Array.isArray(object)
        [start, end] = object
      else
        {start, end} = object
      new Range(start, end)

  constructor: (start, end) ->
    unless this instanceof Range
      return new Range(start, end)
    @start = Point.fromObject(start)
    @end = Point.fromObject(end)

  copy: ->
    new Range(@start, @end)

  negate: ->
    new Range(@start.negate(), @end.negate())

  reverse: ->
    new Range(@end, @start)

  isEmpty: ->
    @start.compare(@end) is 0

  isSingleLine: ->
    @start.row is @end.row

  getRowCount: ->
    @end.row - @start.row + 1

  getRows: ->
    [@start.row..@end.row]

  freeze: ->
    @start.freeze()
    @end.freeze()
    Object.freeze(this)

  union: (other) ->
    other = Range.fromObject(other)
    Range(Point.min(@start, other.start), Point.max(@end, other.end))

  translate: (startDelta, endDelta=startDelta) ->
    startDelta = Point.fromObject(startDelta)
    endDelta = Point.fromObject(endDelta)
    Range(@start.translate(startDelta), @end.translate(endDelta))

  traverse: (delta) ->
    delta = Point.fromObject(delta)
    Range(@start.traverse(delta), @end.traverse(delta))

  compare: (other) ->
    other = Range.fromObject(other)
    if value = @start.compare(other.start)
      value
    else
      other.end.compare(@end)

  isEqual: (other) ->
    other = Range.fromObject(other)
    @start.isEqual(other.start) and @end.isEqual(other.end)

  coversSameRows: (other) ->
    other = Range.fromObject(other)
    @start.row is other.start.row and @end.row is other.end.row

  intersectsWith: (other, exclusive) ->
    other = Range.fromObject(other)
    if exclusive
      @end.isGreaterThan(other.start) and @start.isLessThan(other.end)
    else
      @end.isGreaterThanOrEqual(other.start) and @start.isLessThanOrEqual(other.end)

  intersectsRow: (row) ->
    @start.row <= row <= @end.row or @start.row >= row >= @end.row

  intersectsRowRange: (startRow, endRow) ->
    [startRow, endRow] = [endRow, startRow] if startRow > endRow
    @end.row >= startRow and @start.row <= endRow

  getExtent: ->
    @end.traversalFrom(@start)

  containsPoint: (point, exclusive) ->
    point = Point.fromObject(point)
    if exclusive
      @start.compare(point) < 0 and point.compare(@end) < 0
    else
      @start.compare(point) <= 0 and point.compare(@end) <= 0

  containsRange: (other, exclusive) ->
    other = Range.fromObject(other)
    if exclusive
      @start.isLessThan(other.start) and @end.isGreaterThan(other.end)
    else
      @start.isLessThanOrEqual(other.start) and @end.isGreaterThanOrEqual(other.end)

  @deserialize: (array)->
    Range.fromObject(array)

  serialize: ->
    [@start.serialize(), @end.serialize()]

  toString: ->
    "(#{@start}, #{@end})"
