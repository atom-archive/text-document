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

  isEqual: (other) ->
    other = Range.fromObject(other)
    @start.isEqual(other.start) and @end.isEqual(other.end)

  isEmpty: ->
    @start.compare(@end) is 0

  compare: (other) ->
    other = @constructor.fromObject(other)
    if value = @start.compare(other.start)
      value
    else
      other.end.compare(@end)

  getExtent: ->
    @end.traversalFrom(@start)

  toString: ->
    "(#{@start}, #{@end})"
