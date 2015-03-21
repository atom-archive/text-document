Point = require './point'

module.exports =
class LinesTransform
  operate: ({read, transform}) ->
    if input = read()
      switch (i = input.indexOf("\n"))
        when -1
          transform(input.length)
        when 0
          transform(1, "\n", Point(1, 0))
        else
          transform(i + 1, input.substring(0, i + 1), Point(1, 0))
