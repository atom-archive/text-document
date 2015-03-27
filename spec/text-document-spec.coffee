fs = require "fs"
Point = require "../src/point"
Range = require "../src/range"
TextDocument = require "../src/text-document"

describe "TextDocument", ->
  document = null

  beforeEach ->
    document = new TextDocument

  describe "construction", ->
    it "can be constructed empty", ->
      document = new TextDocument
      expect(document.getLineCount()).toBe 1
      expect(document.getText()).toBe ''
      expect(document.lineForRow(0)).toBe ''
      expect(document.lineEndingForRow(0)).toBe ''

    describe "when text is given", ->
      it "can be constructed with initial text containing no trailing newline", ->
        text = "hello\nworld\r\nhow are you doing?\rlast"
        document = new TextDocument(text)
        expect(document.getLineCount()).toBe 4
        expect(document.getText()).toBe text
        expect(document.lineForRow(0)).toBe 'hello'
        expect(document.lineEndingForRow(0)).toBe '\n'
        expect(document.lineForRow(1)).toBe 'world'
        expect(document.lineEndingForRow(1)).toBe '\r\n'
        expect(document.lineForRow(2)).toBe 'how are you doing?'
        expect(document.lineEndingForRow(2)).toBe '\r'
        expect(document.lineForRow(3)).toBe 'last'
        expect(document.lineEndingForRow(3)).toBe ''

      it "can be constructed with initial text containing a trailing newline", ->
        text = "first\n"
        document = new TextDocument(text)
        expect(document.getLineCount()).toBe 2
        expect(document.getText()).toBe text
        expect(document.lineForRow(0)).toBe 'first'
        expect(document.lineEndingForRow(0)).toBe '\n'
        expect(document.lineForRow(1)).toBe ''
        expect(document.lineEndingForRow(1)).toBe ''

    describe "when a file path is given", ->
      afterEach ->
        document?.destroy()

      describe "when a file exists for the path", ->
        it "loads the contents of that file", (done) ->
          filePath = require.resolve('./fixtures/sample.js')
          document = new TextDocument({filePath})

          expect(document.loaded).toBe false
          document.load().then ->
            expect(document.getText()).toBe fs.readFileSync(filePath, 'utf8')
            done()

      describe "when no file exists for the path", ->
        it "is not modified and is initially empty", (done) ->
          filePath = "does-not-exist.txt"
          expect(fs.existsSync(filePath)).toBeFalsy()
          document = new TextDocument({filePath})
          document.load().then ->
            expect(document.isModified()).not.toBeTruthy()
            expect(document.getText()).toBe ''
            done()

  describe "lifecycle", ->
    it "starts out with a reference count of 1", ->
      destroyCallback = jasmine.createSpy("destroyCallback")
      document.onDidDestroy(destroyCallback)

      document.retain()
      document.release()
      expect(destroyCallback).not.toHaveBeenCalled()
      expect(document.isAlive()).toBe true
      expect(document.isDestroyed()).toBe false

      document.retain()
      document.retain()
      document.release()
      document.release()
      expect(destroyCallback).not.toHaveBeenCalled()
      expect(document.isAlive()).toBe true
      expect(document.isDestroyed()).toBe false

      document.release()
      expect(destroyCallback).toHaveBeenCalled()
      expect(document.isAlive()).toBe false
      expect(document.isDestroyed()).toBe true

  describe "position translation", ->
    describe "::clipPosition(position)", ->
      it "returns a valid position closest to the given position", ->
        document = new TextDocument
        document.setText("hello\nworld\nhow are you doing?")

        expect(document.clipPosition([-1, -1])).toEqual Point(0, 0)
        expect(document.clipPosition([-1, 2])).toEqual Point(0, 0)
        expect(document.clipPosition([0, -1])).toEqual Point(0, 0)
        expect(document.clipPosition([0, 20])).toEqual Point(0, 5)
        expect(document.clipPosition([1, -1])).toEqual Point(1, 0)
        expect(document.clipPosition([1, 20])).toEqual Point(1, 5)
        expect(document.clipPosition([10, 0])).toEqual Point(2, 18)
        expect(document.clipPosition([Infinity, 0])).toEqual Point(2, 18)

    describe "::characterIndexForPosition(position)", ->
      beforeEach ->
        document = new TextDocument
        document.setText("zero\none\r\ntwo\nthree")

      it "returns the absolute character offset for the given position", ->
        expect(document.characterIndexForPosition([0, 0])).toBe 0
        expect(document.characterIndexForPosition([0, 1])).toBe 1
        expect(document.characterIndexForPosition([0, 4])).toBe 4
        expect(document.characterIndexForPosition([1, 0])).toBe 5
        expect(document.characterIndexForPosition([1, 1])).toBe 6
        expect(document.characterIndexForPosition([1, 3])).toBe 8
        expect(document.characterIndexForPosition([2, 0])).toBe 10
        expect(document.characterIndexForPosition([2, 1])).toBe 11
        expect(document.characterIndexForPosition([3, 0])).toBe 14
        expect(document.characterIndexForPosition([3, 5])).toBe 19

      it "clips the given position before translating", ->
        expect(document.characterIndexForPosition([-1, -1])).toBe 0
        expect(document.characterIndexForPosition([1, 100])).toBe 8
        expect(document.characterIndexForPosition([100, 100])).toBe 19

    describe "::positionForCharacterIndex(offset)", ->
      beforeEach ->
        document = new TextDocument
        document.setText("zero\none\r\ntwo\nthree")

      it "returns the position for the given absolute character offset", ->
        expect(document.positionForCharacterIndex(0)).toEqual Point(0, 0)
        expect(document.positionForCharacterIndex(1)).toEqual Point(0, 1)
        expect(document.positionForCharacterIndex(4)).toEqual Point(0, 4)
        expect(document.positionForCharacterIndex(5)).toEqual Point(1, 0)
        expect(document.positionForCharacterIndex(6)).toEqual Point(1, 1)
        expect(document.positionForCharacterIndex(8)).toEqual Point(1, 3)
        expect(document.positionForCharacterIndex(9)).toEqual Point(1, 3)
        expect(document.positionForCharacterIndex(10)).toEqual Point(2, 0)
        expect(document.positionForCharacterIndex(11)).toEqual Point(2, 1)
        expect(document.positionForCharacterIndex(14)).toEqual Point(3, 0)
        expect(document.positionForCharacterIndex(19)).toEqual Point(3, 5)

      it "clips the given offset before translating", ->
        expect(document.positionForCharacterIndex(-1)).toEqual Point(0, 0)
        expect(document.positionForCharacterIndex(20)).toEqual Point(3, 5)

  describe "markers", ->
    describe "::markPosition", ->
      it "returns a marker for the given position with the given properties", ->
        marker = document.markPosition([0, 6], a: '1')
        expect(marker.getRange()).toEqual Range(Point(0, 6), Point(0, 6))
        expect(marker.getHeadPosition()).toEqual Point(0, 6)
        expect(marker.getTailPosition()).toEqual Point(0, 6)
        expect(marker.getProperties()).toEqual {a: '1'}

        expect(marker.matchesParams({})).toBe true
        expect(marker.matchesParams(a: '1')).toBe true
        expect(marker.matchesParams(a: '2')).toBe false

      it "allows the marker to be retrieved with ::findMarkers(properties)", ->
        marker1 = document.markPosition([0, 6], a: '1', b: '2')
        marker2 = document.markPosition([0, 6], a: '1', b: '3')
        marker3 = document.markPosition([0, 6], a: '2', )

        expect(document.findMarkers(a: '1')).toEqual([marker1, marker2])

      it "allows the marker to be retrieved with ::getMarker(id)", ->
        marker1 = document.markPosition([0, 6], a: '1', b: '2')
        marker2 = document.markPosition([0, 6], a: '1', b: '3')
        marker3 = document.markPosition([0, 6], a: '2', )

        expect(document.getMarker(marker1.id)).toBe marker1
        expect(document.getMarker(marker2.id)).toBe marker2
        expect(document.getMarker(marker3.id)).toBe marker3
        expect(document.getMarker(1234)).toBeUndefined()

      it "calls callbacks registered with ::onDidCreateMarker(fn)", ->
        createdMarkers = []
        document.onDidCreateMarker (marker) ->
          expect(marker).toBe document.getMarker(marker.id)
          createdMarkers.push(marker)

        marker = document.markPosition([0, 6])
        expect(createdMarkers).toEqual([marker])

    describe "Marker::setProperties", ->
      it "allows the properties to be retrieved", ->
        marker = document.markPosition([0, 6], a: '1')
        marker.setProperties(b: '2')

        expect(marker.getProperties()).toEqual(a: '1', b: '2')
        expect(document.findMarkers(b: '2')).toEqual [marker]

  describe "manipulating text", ->
    describe "::isEmpty", ->
      it "returns true if the document has no text", ->
        expect(document.isEmpty()).toBe true
        document.setText("a")
        expect(document.isEmpty()).toBe false

    describe "::getTextInRange(range)", ->
      it "returns the text between the range's start and end positions", ->
        document.setText """
          one
          two
          three
          four
        """

        expect(document.getTextInRange([[1, 2], [2, 4]])).toBe """
          o
          thre
        """

    describe "::setTextInRange(range, text)", ->
      it "replaces the text in the given range with the given text", ->
        changeEvents = []
        document.onDidChange (event) -> changeEvents.push(event)

        document.setText """
          one
          two
          three
          four
        """

        newRange = document.setTextInRange([[1, 2], [2, 4]], "inkl")
        expect(document.getText()).toBe """
          one
          twinkle
          four
        """

        expect(newRange).toEqual(Range(Point(1, 2), Point(1, 6)))
        expect(changeEvents).toEqual([{
          oldText: "o\nthre"
          newText: "inkl"
          oldRange: Range(Point(1, 2), Point(2, 4))
          newRange: Range(Point(1, 2), Point(1, 6))
        }])

      it "calls callbacks registered with ::onDidChange(fn)", ->

  describe "file details", ->
    describe "encoding", ->
      it "uses utf8 by default", ->
        expect(document.getEncoding()).toBe "utf8"

      it "allows the encoding to be set with ::setEncoding(encoding)", ->
        document.setEncoding("ascii")
        expect(document.getEncoding()).toBe "ascii"
