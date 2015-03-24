Point = require './point'

LineBreak = /\r?\n|\r/

module.exports =
class LinesTransform
  operate: ({read, transform, clipping}) ->
    if input = read()
      if match = input.match(LineBreak)
        if match.index is 0
          transform(match[0].length, match[0], Point(1, 0))
        else
          transform(match.index)
          transform(match[0].length, match[0], Point(1, 0), clipping.open)
      else
        transform(input.length)
