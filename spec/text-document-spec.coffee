Point = require "../src/point"
TextDocument = require "../src/text-document"

describe "TextDocument", ->
  [document, layer] = []

  beforeEach ->
    document = new TextDocument
    document.setText("""
      abcd\tefg

      hij
    """)

    layer = document.buildDisplayLayer(
      softWrapColumn: 10
      tabLength: 4
    )

  describe "::buildDisplayLayer()", ->
    describe "::slice(start, end)", ->
      it "returns the content between the start and end points", ->
        expect(layer.getLines()).toEqual [
          "abcd\t   "
          "efg\n"
          "\n"
          "hij"
        ]

    it "maps positions correctly across multiple layers", ->
      expectMappings(layer, document.bufferLayer, [
        [Point(0, 0), Point(0, 0)]
        [Point(1, 0), Point(0, 5)]
        [Point(2, 0), Point(0, 9)]
        [Point(3, 0), Point(0, 10)]
        [Point(3, 1), Point(0, 11)]
      ])
