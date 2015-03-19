module.exports =
class HardTabsTransform
  constructor: (@tabLength) ->

  operate: ({read, consume, passThrough, produceCharacters, getPosition}) ->
    if (input = read())?
      switch (i = input.indexOf("\t"))
        when -1
          passThrough(input.length)
        when 0
          consume(1)
          produceCharacters(@tabStringForColumn(getPosition().column))
        else
          passThrough(i)
          consume(1)
          produceCharacters(@tabStringForColumn(getPosition().column))

  tabStringForColumn: (column) ->
    length = @tabLength - (column % @tabLength)
    result = "\t"
    result += " " for i in [1...length] by 1
    result
