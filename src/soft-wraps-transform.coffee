WhitespaceRegExp = /\s/

module.exports =
class SoftWrapsTransform
  constructor: (@maxLineLength) ->

  operate: ({read, consume, produceCharacters, produceNewline, getPosition}) ->
    maxCharacters = @maxLineLength - getPosition().column

    if input = read()
      lastWhitespaceIndex = null
      for i in [0...input.length] by 1
        if WhitespaceRegExp.test(input[i])
          lastWhitespaceIndex = i
        else if i >= maxCharacters
          break

      if lastWhitespaceIndex?
        consume(lastWhitespaceIndex + 1)
        produceCharacters(input.substr(0, lastWhitespaceIndex + 1))
        produceNewline()
      else if input.length > maxCharacters
        consume(maxCharacters)
        produceCharacters(input.substr(0, maxCharacters))
        produceNewline()
      else
        consume(input.length)
        produceCharacters(input)
