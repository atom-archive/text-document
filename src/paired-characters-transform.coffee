{EOF, Character} = require "./symbols"

module.exports =
class PairedCharactersTransform
  operate: ({read, consume, produce}) ->
    input = read()

    if input is EOF
      produce(EOF)
      return

    for i in [0...input.length - 1] by 1
      if isPairedCharacter(input.charCodeAt(i), input.charCodeAt(i + 1))
        consume(i)
        produce(input.substring(0, i))

        consume(2)
        produce(new Character(input.substring(i, i + 2)))
        return

    consume(input.length)
    produce(input)

# Is the character at the given index the start of high/low surrogate pair
# a variation sequence, or a combined character?
#
# * `string` The {String} to check for a surrogate pair, variation sequence,
#            or combined character.
# * `index`  The {Number} index to look for a surrogate pair, variation
#            sequence, or combined character.
#
# Return a {Boolean}.
isPairedCharacter = (charCodeA, charCodeB) ->
  isSurrogatePair(charCodeA, charCodeB) or
    isVariationSequence(charCodeA, charCodeB) or
      isCombinedCharacter(charCodeA, charCodeB)

# Are the given character codes a high/low surrogate pair?
#
# * `charCodeA` The first character code {Number}.
# * `charCode2` The second character code {Number}.
#
# Return a {Boolean}.
isSurrogatePair = (charCodeA, charCodeB) ->
  isHighSurrogate(charCodeA) and isLowSurrogate(charCodeB)

# Are the given character codes a variation sequence?
#
# * `charCodeA` The first character code {Number}.
# * `charCode2` The second character code {Number}.
#
# Return a {Boolean}.
isVariationSequence = (charCodeA, charCodeB) ->
  not isVariationSelector(charCodeA) and isVariationSelector(charCodeB)

# Are the given character codes a combined character pair?
#
# * `charCodeA` The first character code {Number}.
# * `charCode2` The second character code {Number}.
#
# Return a {Boolean}.
isCombinedCharacter = (charCodeA, charCodeB) ->
  not isCombiningCharacter(charCodeA) and isCombiningCharacter(charCodeB)

isHighSurrogate = (charCode) ->
  0xD800 <= charCode <= 0xDBFF

isLowSurrogate = (charCode) ->
  0xDC00 <= charCode <= 0xDFFF

isVariationSelector = (charCode) ->
  0xFE00 <= charCode <= 0xFE0F

isCombiningCharacter = (charCode) ->
  0x0300 <= charCode <= 0x036F or
  0x1AB0 <= charCode <= 0x1AFF or
  0x1DC0 <= charCode <= 0x1DFF or
  0x20D0 <= charCode <= 0x20FF or
  0xFE20 <= charCode <= 0xFE2F
