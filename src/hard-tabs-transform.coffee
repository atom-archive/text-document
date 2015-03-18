module.exports =
class HardTabsTransform
  constructor: (@tabLength) ->

  operate: ({read, consume, produceCharacters, getPosition}) ->
    if input = read()
      switch (i = input.indexOf("\t"))
        when -1
          consume(input.length)
          produceCharacters(input)
        when 0
          consume(1)
          produceCharacters(@tabStringForColumn(getPosition().column))
        else
          consume(i)
          produceCharacters(input.slice(0, i))
          consume(1)
          produceCharacters(@tabStringForColumn(getPosition().column))

  tabStringForColumn: (column) ->
    length = @tabLength - (column % @tabLength)
    result = "\t"
    result += " " for i in [1...length] by 1
    result
