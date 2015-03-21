module.exports =
class HardTabsTransform
  constructor: (@tabLength) ->

  operate: ({read, transduce, getPosition}) ->
    if (input = read())?
      switch (i = input.indexOf("\t"))
        when -1
          transduce(input.length)
        when 0
          transduce(1, @tabStringForColumn(getPosition().column))
        else
          transduce(i)
          transduce(1, @tabStringForColumn(getPosition().column))

  tabStringForColumn: (column) ->
    length = @tabLength - (column % @tabLength)
    result = "\t"
    result += " " for i in [1...length] by 1
    result
