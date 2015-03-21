Point = require "../src/point"
TextDocument = require "../src/text-document"

describe "TextDocument", ->
  [document, layer] = []

  describe "::buildDisplayLayer()", ->
    describe "::slice(start, end)", ->
      it "returns the content between the start and end points", ->
        document = new TextDocument(softWrapColumn: 10, tabLength: 4)
        document.setText("""
          abcd\tefg

          hij
        """)
        expect(document.displayLayer.getLines()).toEqual [
          "abcd\t   "
          "efg\n"
          "\n"
          "hij"
        ]

  describe "position translation", ->
    beforeEach ->
      document = new TextDocument(softWrapColumn: 100, tabLength: 2)
      document.setText("zero\none\r\ntwo\nthree")

    describe "::characterIndexForPosition(position)", ->
      it "returns the absolute character offset for the given position", ->
        expect(document.characterIndexForPosition(Point(0, 0))).toBe 0
        expect(document.characterIndexForPosition(Point(0, 1))).toBe 1
        expect(document.characterIndexForPosition(Point(0, 4))).toBe 4
        expect(document.characterIndexForPosition(Point(1, 0))).toBe 5
        expect(document.characterIndexForPosition(Point(1, 1))).toBe 6
        expect(document.characterIndexForPosition(Point(1, 3))).toBe 8
        expect(document.characterIndexForPosition(Point(2, 0))).toBe 10
        expect(document.characterIndexForPosition(Point(2, 1))).toBe 11
        expect(document.characterIndexForPosition(Point(3, 0))).toBe 14
        expect(document.characterIndexForPosition(Point(3, 5))).toBe 19

    describe "::positionForCharacterIndex(offset)", ->
      it "returns the position for the given absolute character offset", ->
        expect(document.positionForCharacterIndex(0)).toEqual Point(0, 0)
        expect(document.positionForCharacterIndex(1)).toEqual Point(0, 1)
        expect(document.positionForCharacterIndex(4)).toEqual Point(0, 4)
        expect(document.positionForCharacterIndex(5)).toEqual Point(1, 0)
        expect(document.positionForCharacterIndex(6)).toEqual Point(1, 1)
        expect(document.positionForCharacterIndex(8)).toEqual Point(1, 3)
        expect(document.positionForCharacterIndex(10)).toEqual Point(2, 0)
        expect(document.positionForCharacterIndex(11)).toEqual Point(2, 1)
        expect(document.positionForCharacterIndex(14)).toEqual Point(3, 0)
        expect(document.positionForCharacterIndex(19)).toEqual Point(3, 5)
