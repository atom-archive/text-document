module.exports =
class LinesTransform
  operate: ({read, consume, produceCharacters, produceNewline}) ->
    if input = read()
      switch (i = input.indexOf("\n"))
        when -1
          consume(input.length)
          produceCharacters(input)
        when 0
          consume(1)
          produceCharacters("\n")
          produceNewline()
        else
          consume(i + 1)
          produceCharacters(input.slice(0, i + 1))
          produceNewline()
