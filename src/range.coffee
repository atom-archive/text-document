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
    @start is other.start and @end is other.end

  isEmpty: ->
    @start.compare(@end) is 0
