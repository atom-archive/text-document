fs = require "fs"
path = require "path"
Point = require "../src/point"
TextDocument = require "../src/text-document"
TextDisplayDocument = require "../src/text-display-document"

describe "TextDisplayDocument", ->
  [document, displayDocument] = []

  beforeEach ->
    document = new TextDocument

  describe "::tokenizedLinesForScreenRows(start, end)", ->
    it "accounts for hard tabs and soft wraps", ->
      document.setText("""
        abcd\tefg

        hij
      """)

      displayDocument = new TextDisplayDocument(document,
        tabLength: 4
        softWrapColumn: 10
      )

      tokenizedLines = displayDocument.tokenizedLinesForScreenRows(0, Infinity)
      expect(tokenizedLines.map (line) -> line.text).toEqual [
        "abcd\t   "
        "efg\n"
        "\n"
        "hij"
      ]

  describe "position translation", ->
    beforeEach ->
      document.setText(fs.readFileSync(path.join(__dirname, "fixtures", "sample.js"), 'utf8'))

      displayDocument = new TextDisplayDocument(document,
        tabLength: 4
        softWrapColumn: 50
      )

    describe "with soft wrapping", ->
      it "translates positions accounting for wrapped lines", ->
        # before any wrapped lines, within a line
        expect(displayDocument.screenPositionForBufferPosition([0, 5])).toEqual(Point(0, 5))
        expect(displayDocument.bufferPositionForScreenPosition([0, 5])).toEqual(Point(0, 5))

        # before any wrapped lines, at the end of line
        expect(displayDocument.screenPositionForBufferPosition([0, 29])).toEqual(Point(0, 29))
        expect(displayDocument.bufferPositionForScreenPosition([0, 29])).toEqual(Point(0, 29))

        # before any wrapped lines, past the end of the line
        expect(displayDocument.screenPositionForBufferPosition([0, 31])).toEqual(Point(0, 29))
        expect(displayDocument.bufferPositionForScreenPosition([0, 31])).toEqual(Point(0, 29))

        # on a wrapped line, at the wrap column
        expect(displayDocument.screenPositionForBufferPosition([3, 50])).toEqual(Point(3, 50))
        expect(displayDocument.bufferPositionForScreenPosition([3, 50])).toEqual(Point(3, 50))

        # on a wrapped line, past the wrap column
        expect(displayDocument.screenPositionForBufferPosition([3, 51])).toEqual(Point(4, 0))
        expect(displayDocument.bufferPositionForScreenPosition([3, 51])).toEqual(Point(3, 50))
        expect(displayDocument.bufferPositionForScreenPosition([3, 55])).toEqual(Point(3, 50))
        expect(displayDocument.screenPositionForBufferPosition([3, 62])).toEqual(Point(4, 11))
        expect(displayDocument.bufferPositionForScreenPosition([4, 11])).toEqual(Point(3, 62))

        # after a wrapped line
        expect(displayDocument.screenPositionForBufferPosition([4, 5])).toEqual(Point(5, 5))
        expect(displayDocument.bufferPositionForScreenPosition([5, 5])).toEqual(Point(4, 5))

        # invalid screen positions
        expect(displayDocument.bufferPositionForScreenPosition([-5, -5])).toEqual(Point(0, 0))
        expect(displayDocument.bufferPositionForScreenPosition([Infinity, Infinity])).toEqual(Point(12, 2))
        expect(displayDocument.bufferPositionForScreenPosition([3, -5])).toEqual(Point(3, 0))
        expect(displayDocument.bufferPositionForScreenPosition([3, Infinity])).toEqual(Point(3, 50))
