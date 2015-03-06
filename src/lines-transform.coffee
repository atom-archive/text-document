{Newline, EOF} = require "./symbols"

module.exports =
class LinesTransform
  operate: ({read, consume, produce}) ->
    switch (input = read())
      when EOF
        produce(EOF)
      when Newline
        produce(Newline)
      else
        switch (i = input.indexOf("\n", i))
          when -1
            consume(input.length)
            produce(input)
          when 0
            consume(1)
            produce("\n")
            produce(Newline)
          else
            consume(i + 1)
            produce(input.slice(0, i + 1))
            produce(Newline)
