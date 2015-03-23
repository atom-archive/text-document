module.exports =
class HardTabsTransform
  constructor: (@tabLength) ->

  operate: ({read, transform, getPosition, clipping}) ->
    if (input = read())?
      switch (i = input.indexOf("\t"))
        when -1
          transform(input.length)
        when 0
          transform(1, @tabStringForColumn(getPosition().column), null, clipping.open)
        else
          transform(i)
          transform(1, @tabStringForColumn(getPosition().column), null, clipping.open)

  tabStringForColumn: (column) ->
    length = @tabLength - (column % @tabLength)
    result = "\t"
    result += " " for i in [1...length] by 1
    result
