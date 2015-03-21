Point = require './point'
WhitespaceRegExp = /\s/

module.exports =
class SoftWrapsTransform
  constructor: (@maxColumn) ->

  operate: ({read, transform, getPosition}) ->
    {column} = getPosition()
    startColumn = column
    lastWhitespaceColumn = null
    output = ""

    while (input = read())?
      lastOutputLength = output.length
      output += input

      for i in [0...input.length] by 1
        if input[i] is "\n"
          transform(lastOutputLength + i + 1)
          return

        if WhitespaceRegExp.test(input[i])
          lastWhitespaceColumn = column
        else if column >= @maxColumn
          if lastWhitespaceColumn?
            output = output.substring(0, lastWhitespaceColumn - startColumn + 1)
          else
            output = output.substring(0, lastOutputLength + i)

          transform(output.length, output, Point(1, 0))
          return

        column++

    if output.length > 0
      transform(output.length)
