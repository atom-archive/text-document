Point = require "../src/point"
TextDocument = require "../src/text-document"

describe "TextDocument", ->
  document = null

  beforeEach ->
    document = new TextDocument

  describe "::buildDisplayLayer()", ->
    describe "::slice(start, end)", ->
      it "returns the content between the start and end points", ->
        document.setText("""
          abcd\tefg

          hij
        """)

        layer = document.buildDisplayLayer(
          softWrapColumn: 10
          tabLength: 4
        )

        expect(layer.getLines()).toEqual [
          "abcd\t   "
          "efg\n"
          "\n"
          "hij"
        ]
