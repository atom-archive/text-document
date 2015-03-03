{Newline, EOF} = require "./symbols"

module.exports =
class LinesTransform
  initialize: () ->

  operate: (source, target) ->
    switch (input = source.read())
      when EOF
        target.produce(EOF)
      when Newline
        target.produce(Newline)
      else
        switch (i = input.indexOf("\n", i))
          when -1
            source.consume(input.length)
            target.produce(input)
          when 0
            source.consume(1)
            target.produce(Newline)
          else
            source.consume(i)
            target.produce(input.slice(0, i))
            source.consume(1)
            target.produce(Newline)
