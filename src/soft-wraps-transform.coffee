Point = require './point'
WhitespaceRegExp = /\s/
unless document?
  Canvas = require 'canvas'

module.exports =
class SoftWrapsTransform
  # see http://en.wikipedia.org/wiki/Line_breaking_rules_in_East_Asian_languages
  # exclude ASCII code
  @notAllowedStartRegExp: ///[
    ¢¨°·ˇˉ―‖’”„‟†‡›℃∶、。〃〆〈《「『〕〗〞︵︹︽︿﹃﹘﹚﹜！＂％
    ＇），．：；？］｀｜｝～–—•‥„‧†╴〞︰︱︲︳︵︷︹︻︽︿﹁﹃﹏﹐﹑﹒﹓﹔﹕﹖﹘﹚﹜！，．､〉》」』】〙〟｠»ヽヾーァィゥェォッャュョヮヵヶぁぃ
    ぅぇぉっゃゅょゎゕゖㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿ々〻‐゠〜‼⁇⁈⁉・
  ]///
  @notAllowedEndRegExp: ///[
    £¥·‘“〈《「『【〔〖〝﹗﹙﹛＄（．［｛￡￥‵々〇〉》」〝︴︶︸︺︼︾﹀
    ﹂｟«｠￥￦
  ]///
  # TODO: not implument for not split chracater
  # @notSplitRegExp: /[—…‥〳〴〵]/
  @breakableRegExp: ///[
    \u4e00-\u9fff\u3400-\u4dbf\u3041-\u309f\u30a1-\u30ff\u31f0-\u31ff
    \u1100-\u11ff\u3130-\u318f\uac00-\ud7af
  ]///

  constructor: (@maxColumn, @calcProportionalSize = false,
      fontSize = 0, fontFamily = "", baseCharacter = 'x') ->
    if @calcProportionalSize
      # HACK: chromium can use document, but pure node.js uses node-canvas
      canvas = document?.createElement("canvas") || new Canvas(0, 0)
      @context = canvas.getContext("2d")
      # TODO: if fontFamily contains "'", then fontFamily is broken
      @context.font = "#{fontSize}px '#{fontFamily}'"
      @maxWidth = @context.measureText([0..@maxColumn].reduce(
        ((a, _) -> a + baseCharacter), "")).width

  operate: ({read, transform, getPosition}) ->
    if @calcProportionalSize
      @operateProportionalSize({read, transform, getPosition})
    else
      @operateSingleSize({read, transform, getPosition})

  operateSingleSize: ({read, transform, getPosition}) ->
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

  operateProportionalSize: ({read, transform, getPosition}) ->
    {column} = getPosition()
    startColumn = column
    output = ""
    startColumnText = [0..startColumn].reduce ((a, _) -> a + " "), ""
    brekableColumns = []
    nonBreakableColumns = []

    while (input = read())?
      lastOutputLength = output.length
      output += input

      for i in [0...input.length] by 1
        if input[i] is "\n"
          transform(lastOutputLength + i + 1)
          return

        if WhitespaceRegExp.test(input[i])
          brekableColumns.push(column + 1)
          nonBreakableColumns.push(column)
        else
          if SoftWrapsTransform.breakableRegExp.test(input[i])
            brekableColumns.push(column)
            brekableColumns.push(column + 1)
          if SoftWrapsTransform.notAllowedStartRegExp.test(input[i])
            nonBreakableColumns.push(column)
          if SoftWrapsTransform.notAllowedEndRegExp.test(input[i])
            nonBreakableColumns.push(column + 1)

          if @context.measureText(startColumnText + input[0..i]).width >=
              @maxWidth
            nonBreakableColumns.push(column + 1)

            # `([-1] + a - b).max` as Ruby
            last = 0
            len = nonBreakableColumns.length
            lastBreakableColumn = brekableColumns.filter (n) ->
              last++ while last + 1 < len && nonBreakableColumns[last] < n
              nonBreakableColumns[last] != n
            .reduce (p, n) ->
              Math.max(p, n)
            , -1

            if lastBreakableColumn > 0
              output = output.substring(0, lastBreakableColumn - startColumn)
            else
              output = output.substring(0, lastOutputLength + i)

            transform(output.length, output, Point(1, 0))
            return

        column++

    if output.length > 0
      transform(output.length)
