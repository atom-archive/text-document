module.exports =
class LinesTransform
  operate: ({read, consume, passThrough, produceNewline}) ->
    if input = read()
      switch (i = input.indexOf("\n"))
        when -1
          passThrough(input.length)
        when 0
          passThrough(1)
          produceNewline()
        else
          passThrough(i + 1)
          produceNewline()
