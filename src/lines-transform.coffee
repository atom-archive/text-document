Point = require './point'

module.exports =
class LinesTransform
  operate: ({read, transduce}) ->
    if input = read()
      switch (i = input.indexOf("\n"))
        when -1
          transduce(input.length)
        when 0
          transduce(1, "\n", Point(1, 0))
        else
          transduce(i + 1, input.substring(0, i + 1), Point(1, 0))
