Point = require './point'

module.exports =
class LinesTransform
  operate: ({read, transform, clipping}) ->
    if input = read()
      switch (i = input.indexOf("\n"))
        when -1
          transform(input.length)
        when 0
          transform(1, "\n", Point(1, 0))
        else
          carriage = input[i - 1] == "\r" ? 1 : 0

          transform(i - carriage)
          transform(1 + carriage, "\n", Point(1, 0), clipping.open)
