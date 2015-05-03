Point = require './point'
WhitespaceRegExp = /\s/
unless document?
  Canvas = require 'canvas'

module.exports =
class SoftWrapsTransform
  constructor: (@maxColumn, @calcProportionalSize = false,
      {fontFamily, fontSize, baseCharacter} = {"", 0, 'x'}) ->
    if @calcProportionalSize
      # HACK: chromium can use document, but pure node.js uses node-canvas
      canvas = document?.createElement("canvas") || new Canvas(0, 0)
      @context = canvas.getContext("2d")
      # TODO: if fontFamily contains "'", then fontFamily is broken
      @context.font = "#{fontSize}px '#{fontFamily}'"
      @baseWidth = @context.measureText(baseCharacter).width

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
    return
