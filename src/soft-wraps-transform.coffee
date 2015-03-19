WhitespaceRegExp = /\s/

module.exports =
class SoftWrapsTransform
  constructor: (@maxColumn) ->

  operate: ({read, consume, produceCharacters, produceNewline, getPosition}) ->
    {column} = getPosition()
    startColumn = column
    lastWhitespaceColumn = null
    output = ""

    while input = read()
      lastOutputLength = output.length
      output += input

      for i in [0...input.length] by 1
        if input[i] is "\n"
          output = output.substring(0, lastOutputLength + i + 1)
          consume(output.length)
          produceCharacters(output)
          return

        if WhitespaceRegExp.test(input[i])
          lastWhitespaceColumn = column
        else if column >= @maxColumn
          if lastWhitespaceColumn?
            output = output.substring(0, lastWhitespaceColumn - startColumn + 1)
          else
            output = output.substring(0, lastOutputLength + i)

          consume(output.length)
          produceCharacters(output)
          produceNewline()
          return

        column++

    if output.length > 0
      consume(output.length)
      produceCharacters(output)
