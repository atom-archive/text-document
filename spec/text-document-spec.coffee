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
          document.load().then (value) ->
            expect(value).toBe document
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

    describe "::rangeForRow(row, includeNewline)", ->
      beforeEach ->
        document = new TextDocument("this\nis a test\r\ntesting")

      describe "if includeNewline is false (the default)", ->
        it "returns a range from the beginning of the line to the end of the line", ->
          expect(document.rangeForRow(0)).toEqual([[0, 0], [0, 4]])
          expect(document.rangeForRow(1)).toEqual([[1, 0], [1, 9]])
          expect(document.rangeForRow(2)).toEqual([[2, 0], [2, 7]])

      describe "if includeNewline is true", ->
        it "returns a range from the beginning of the line to the beginning of the next (if it exists)", ->
          expect(document.rangeForRow(0, true)).toEqual([[0, 0], [1, 0]])
          expect(document.rangeForRow(1, true)).toEqual([[1, 0], [2, 0]])
          expect(document.rangeForRow(2, true)).toEqual([[2, 0], [2, 7]])

    describe "::getRange()", ->
      it "returns the range spanned by the document's text", ->
        document = new TextDocument("one\ntwo\nthree")
        expect(document.getRange()).toEqual([[0, 0], [2, 5]])

  describe "markers", ->
    describe "::markPosition(position, properties)", ->
      it "returns a marker for the given position with the given properties (plus defaults)", ->
        marker = document.markPosition([0, 6], a: '1')
        expect(marker.getRange()).toEqual Range(Point(0, 6), Point(0, 6))
        expect(marker.getHeadPosition()).toEqual Point(0, 6)
        expect(marker.getTailPosition()).toEqual Point(0, 6)
        expect(marker.getProperties()).toEqual {a: '1'}

        expect(marker.matchesParams({})).toBe true
        expect(marker.matchesParams(a: '1')).toBe true
        expect(marker.matchesParams(a: '2')).toBe false

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

    describe "::markRange(range, properties)", ->
      it "returns a marker for the given range with the given properties (plus defaults)", ->
        marker = document.markRange([[0, 6], [1, 7]], a: '1')
        expect(marker.getRange()).toEqual Range(Point(0, 6), Point(1, 7))
        expect(marker.getHeadPosition()).toEqual Point(1, 7)
        expect(marker.getTailPosition()).toEqual Point(0, 6)
        expect(marker.getProperties()).toEqual {a: '1'}

    describe "::findMarkers(properties)", ->
      [marker1, marker2, marker3, marker4] = []

      getIds = (markers) ->
        markers.map (marker) -> marker.id

      beforeEach ->
        document.setText("abcdefghijklmnopqrstuvwxyz")
        marker1 = document.markRange([[0, 0], [0, 3]], class: 'a')
        marker2 = document.markRange([[0, 0], [0, 5]], class: 'a', invalidate: 'surround')
        marker3 = document.markRange([[0, 4], [0, 7]], class: 'a')
        marker4 = document.markRange([[0, 0], [0, 7]], class: 'b', invalidate: 'never')

      it "can find markers based on custom properties", ->
        expect(document.findMarkers(class: 'a')).toEqual [marker2, marker1, marker3]
        expect(document.findMarkers(class: 'b')).toEqual [marker4]

      it "can find markers based on their invalidation strategy", ->
        expect(document.findMarkers(invalidate: 'overlap')).toEqual [marker1, marker3]
        expect(document.findMarkers(invalidate: 'surround')).toEqual [marker2]
        expect(document.findMarkers(invalidate: 'never')).toEqual [marker4]

      it "can find markers that start or end at a given position", ->
        expect(document.findMarkers(startPosition: [0, 0])).toEqual [marker4, marker2, marker1]
        expect(document.findMarkers(startPosition: [0, 0], class: 'a')).toEqual [marker2, marker1]
        expect(document.findMarkers(startPosition: [0, 0], endPosition: [0, 3], class: 'a')).toEqual [marker1]
        expect(document.findMarkers(startPosition: [0, 4], endPosition: [0, 7])).toEqual [marker3]
        expect(document.findMarkers(endPosition: [0, 7])).toEqual [marker4, marker3]
        expect(document.findMarkers(endPosition: [0, 7], class: 'b')).toEqual [marker4]

      it "can find markers that contain a given point", ->
        expect(document.findMarkers(containsPoint: [0, 0])).toEqual [marker4, marker2, marker1]
        expect(document.findMarkers(containsPoint: [0, 1], class: 'a')).toEqual [marker2, marker1]
        expect(document.findMarkers(containsPoint: [0, 4])).toEqual [marker4, marker2, marker3]

      it "can find markers that contain a given range", ->
        expect(document.findMarkers(containsRange: [[0, 1], [0, 4]])).toEqual [marker4, marker2]
        expect(document.findMarkers(containsRange: [[0, 4], [0, 1]])).toEqual [marker4, marker2]
        expect(document.findMarkers(containsRange: [[0, 1], [0, 3]])).toEqual [marker4, marker2, marker1]
        expect(document.findMarkers(containsRange: [[0, 6], [0, 7]])).toEqual [marker4, marker3]

      it "can find markers that intersect a given range", ->
        expect(document.findMarkers(intersectsRange: [[0, 4], [0, 6]])).toEqual [marker4, marker2, marker3]
        expect(document.findMarkers(intersectsRange: [[0, 0], [0, 2]])).toEqual [marker4, marker2, marker1]

      it "can find markers that start or end at a given row", ->
        document.setTextInRange([[0, 7], [0, 7]], '\n')
        document.setTextInRange([[0, 3], [0, 4]], ' \n')
        expect(document.findMarkers(startRow: 0)).toEqual [marker4, marker2, marker1]
        expect(document.findMarkers(startRow: 1)).toEqual [marker3]
        expect(document.findMarkers(endRow: 2)).toEqual [marker4, marker3]
        expect(document.findMarkers(startRow: 0, endRow: 2)).toEqual [marker4]

      it "can find markers that intersect a given row", ->
        document.setTextInRange([[0, 7], [0, 7]], '\n')
        document.setTextInRange([[0, 3], [0, 4]], ' \n')
        expect(document.findMarkers(intersectsRow: 0)).toEqual [marker4, marker2, marker1]
        expect(document.findMarkers(intersectsRow: 1)).toEqual [marker4, marker2, marker3]

      it "can find markers that intersect a given range", ->
        document.setTextInRange([[0, 7], [0, 7]], '\n')
        document.setTextInRange([[0, 3], [0, 4]], ' \n')
        expect(document.findMarkers(intersectsRowRange: [1, 2])).toEqual [marker4, marker2, marker3]

      it "can find markers that are contained within a certain range, inclusive", ->
        expect(document.findMarkers(containedInRange: [[0, 0], [0, 6]])).toEqual [marker2, marker1]
        expect(document.findMarkers(containedInRange: [[0, 4], [0, 7]])).toEqual [marker3]

    describe "direct updates", ->
      [marker, changes] = []

      beforeEach ->
        document.setText("abcdefghijklmnopqrstuvwxyz")
        marker = document.markRange([[0, 6], [0, 9]])
        changes = []
        marker.onDidChange (change) -> changes.push(change)

      describe "::setHeadPosition(position, state)", ->
        it "sets the head position of the marker, flipping its orientation if necessary", ->
          marker.setHeadPosition([0, 12])
          expect(marker.getRange()).toEqual [[0, 6], [0, 12]]
          expect(marker.isReversed()).toBe false
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 12]
            oldTailPosition: [0, 6], newTailPosition: [0, 6]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.setHeadPosition([0, 3])
          expect(marker.getRange()).toEqual [[0, 3], [0, 6]]
          expect(marker.isReversed()).toBe true
          expect(changes).toEqual [{
            oldHeadPosition: [0, 12], newHeadPosition: [0, 3]
            oldTailPosition: [0, 6], newTailPosition: [0, 6]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.setHeadPosition([0, 9])
          expect(marker.getRange()).toEqual [[0, 6], [0, 9]]
          expect(marker.isReversed()).toBe false
          expect(changes).toEqual [{
            oldHeadPosition: [0, 3], newHeadPosition: [0, 9]
            oldTailPosition: [0, 6], newTailPosition: [0, 6]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

        it "does not give the marker a tail if it doesn't have one already", ->
          marker.clearTail()
          expect(marker.hasTail()).toBe false
          marker.setHeadPosition([0, 15])
          expect(marker.hasTail()).toBe false
          expect(marker.getRange()).toEqual [[0, 15], [0, 15]]

        it "does not notify ::onDidChange observers and returns false if the position isn't actually changed", ->
          expect(marker.setHeadPosition(marker.getHeadPosition())).toBe false
          expect(changes.length).toBe 0

        it "allows new properties to be assigned to the state", ->
          marker.setHeadPosition([0, 12], foo: 1)
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 12]
            oldTailPosition: [0, 6], newTailPosition: [0, 6]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {foo: 1}
            textChanged: false
          }]

          changes = []
          marker.setHeadPosition([0, 12], bar: 2)
          expect(marker.getProperties()).toEqual {foo: 1, bar: 2}
          expect(changes).toEqual [{
            oldHeadPosition: [0, 12], newHeadPosition: [0, 12]
            oldTailPosition: [0, 6], newTailPosition: [0, 6]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {foo: 1}, newProperties: {foo: 1, bar: 2}
            textChanged: false
          }]

        it "clips the assigned position", ->
          marker.setHeadPosition([100, 100])
          expect(marker.getHeadPosition()).toEqual [0, 26]

      describe "::setTailPosition(position, state)", ->
        it "sets the tail position of the marker, flipping its orientation if necessary", ->
          marker.setTailPosition([0, 3])
          expect(marker.getRange()).toEqual [[0, 3], [0, 9]]
          expect(marker.isReversed()).toBe false
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 9]
            oldTailPosition: [0, 6], newTailPosition: [0, 3]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.setTailPosition([0, 12])
          expect(marker.getRange()).toEqual [[0, 9], [0, 12]]
          expect(marker.isReversed()).toBe true
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 9]
            oldTailPosition: [0, 3], newTailPosition: [0, 12]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.setTailPosition([0, 6])
          expect(marker.getRange()).toEqual [[0, 6], [0, 9]]
          expect(marker.isReversed()).toBe false
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 9]
            oldTailPosition: [0, 12], newTailPosition: [0, 6]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

        it "plants the tail of the marker if it does not have a tail", ->
          marker.clearTail()
          expect(marker.hasTail()).toBe false
          marker.setTailPosition([0, 0])
          expect(marker.hasTail()).toBe true
          expect(marker.getRange()).toEqual [[0, 0], [0, 9]]

        it "does not notify ::onDidChange observers and returns false if the position isn't actually changed", ->
          expect(marker.setTailPosition(marker.getTailPosition())).toBe false
          expect(changes.length).toBe 0

        it "allows new properties to be assigned to the state", ->
          marker.setTailPosition([0, 3], foo: 1)
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 9]
            oldTailPosition: [0, 6], newTailPosition: [0, 3]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {foo: 1}
            textChanged: false
          }]

          changes = []
          marker.setTailPosition([0, 3], bar: 2)
          expect(marker.getProperties()).toEqual {foo: 1, bar: 2}
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 9]
            oldTailPosition: [0, 3], newTailPosition: [0, 3]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {foo: 1}, newProperties: {foo: 1, bar: 2}
            textChanged: false
          }]

        it "clips the assigned position", ->
          marker.setTailPosition([100, 100])
          expect(marker.getTailPosition()).toEqual [0, 26]

      describe "::setRange(range, options)", ->
        it "sets the head and tail position simultaneously, flipping the orientation if the 'isReversed' option is true", ->
          marker.setRange([[0, 8], [0, 12]])
          expect(marker.getRange()).toEqual [[0, 8], [0, 12]]
          expect(marker.isReversed()).toBe false
          expect(marker.getHeadPosition()).toEqual [0, 12]
          expect(marker.getTailPosition()).toEqual [0, 8]
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 12]
            oldTailPosition: [0, 6], newTailPosition: [0, 8]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.setRange([[0, 3], [0, 9]], reversed: true)
          expect(marker.getRange()).toEqual [[0, 3], [0, 9]]
          expect(marker.isReversed()).toBe true
          expect(marker.getHeadPosition()).toEqual [0, 3]
          expect(marker.getTailPosition()).toEqual [0, 9]
          expect(changes).toEqual [{
            oldHeadPosition: [0, 12], newHeadPosition: [0, 3]
            oldTailPosition: [0, 8], newTailPosition: [0, 9]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

        it "plants the tail of the marker if it does not have a tail", ->
          marker.clearTail()
          expect(marker.hasTail()).toBe false
          marker.setRange([[0, 1], [0, 10]])
          expect(marker.hasTail()).toBe true
          expect(marker.getRange()).toEqual [[0, 1], [0, 10]]

        it "allows new properties to be assigned to the state", ->
          marker.setRange([[0, 1], [0, 2]], foo: 1)
          expect(changes).toEqual [{
            oldHeadPosition: [0, 9], newHeadPosition: [0, 2]
            oldTailPosition: [0, 6], newTailPosition: [0, 1]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {foo: 1}
            textChanged: false
          }]

          changes = []
          marker.setRange([[0, 3], [0, 6]], bar: 2)
          expect(marker.getProperties()).toEqual {foo: 1, bar: 2}
          expect(changes).toEqual [{
            oldHeadPosition: [0, 2], newHeadPosition: [0, 6]
            oldTailPosition: [0, 1], newTailPosition: [0, 3]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {foo: 1}, newProperties: {foo: 1, bar: 2}
            textChanged: false
          }]

        it "clips the assigned range", ->
          marker.setRange([[-100, -100], [100, 100]])
          expect(marker.getRange()).toEqual [[0, 0], [0, 26]]

      describe "::clearTail() / ::plantTail()", ->
        it "clears the tail / plants the tail at the current head position", ->
          marker.setRange([[0, 6], [0, 9]], reversed: true)

          changes = []
          marker.clearTail()
          expect(marker.getRange()).toEqual [[0, 6], [0, 6]]
          expect(marker.hasTail()).toBe false
          expect(marker.isReversed()).toBe false

          expect(changes).toEqual [{
            oldHeadPosition: [0, 6], newHeadPosition: [0, 6]
            oldTailPosition: [0, 9], newTailPosition: [0, 6]
            hadTail: true, hasTail: false
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.setHeadPosition([0, 12])
          expect(marker.getRange()).toEqual [[0, 12], [0, 12]]
          expect(changes).toEqual [{
            oldHeadPosition: [0, 6], newHeadPosition: [0, 12]
            oldTailPosition: [0, 6], newTailPosition: [0, 12]
            hadTail: false, hasTail: false
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.plantTail()
          expect(marker.hasTail()).toBe true
          expect(marker.isReversed()).toBe false
          expect(marker.getRange()).toEqual [12, 12]
          expect(changes).toEqual [{
            oldHeadPosition: [0, 12], newHeadPosition: [0, 12]
            oldTailPosition: [0, 12], newTailPosition: [0, 12]
            hadTail: false, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.setHeadPosition([0, 15])
          expect(marker.getRange()).toEqual [[0, 12], [0, 15]]
          expect(changes).toEqual [{
            oldHeadPosition: [0, 12], newHeadPosition: [0, 15]
            oldTailPosition: [0, 12], newTailPosition: [0, 12]
            hadTail: true, hasTail: true
            wasValid: true, isValid: true
            oldProperties: {}, newProperties: {}
            textChanged: false
          }]

          changes = []
          marker.plantTail()
          expect(marker.getRange()).toEqual [12, 15]
          expect(changes).toEqual []

      describe "::setProperties(properties)", ->
        it "merges the given properties into the current properties", ->
          marker.setProperties(foo: 1)
          expect(marker.getProperties()).toEqual {foo: 1}
          marker.setProperties(bar: 2)
          expect(marker.getProperties()).toEqual {foo: 1, bar: 2}

    describe "Marker::destroy", ->
      it "removes the marker and calls callbacks registered with ::onDidDestroy", ->
        marker = document.markPosition([0, 6], a: '1')
        destroyed = false
        marker.onDidDestroy -> destroyed = true

        marker.destroy()
        expect(document.getMarker(marker.id)).toBeUndefined()
        expect(destroyed).toBe true

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
      beforeEach ->
        document = new TextDocument("hello\nworld\r\nhow are you doing?")

      it "can replace text on a single line with a standard newline", ->
        document.setTextInRange([[0, 2], [0, 4]], "y y")
        expect(document.getText()).toEqual "hey yo\nworld\r\nhow are you doing?"

      it "can replace text on a single line with a carriage-return/newline", ->
        document.setTextInRange([[1, 3], [1, 5]], "ms")
        expect(document.getText()).toEqual "hello\nworms\r\nhow are you doing?"

      it "can replace text in a region spanning multiple lines, ending on the last line", ->
        document.setTextInRange([[0, 2], [2, 3]], "y there\r\ncat\nwhat", normalizeLineEndings: false)
        expect(document.getText()).toEqual "hey there\r\ncat\nwhat are you doing?"

      it "can replace text in a region spanning multiple lines, ending with a carriage-return/newline", ->
        document.setTextInRange([[0, 2], [1, 3]], "y\nyou're o", normalizeLineEndings: false)
        expect(document.getText()).toEqual "hey\nyou're old\r\nhow are you doing?"

      it "notifies ::onWillChange observers with the relevant details before a change", ->
        changes = []
        document.onWillChange (change) ->
          expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"
          changes.push(change)

        document.setTextInRange([[0, 2], [2, 3]], "y there\r\ncat\nwhat", normalizeLineEndings: false)
        expect(changes).toEqual [{
          oldRange: [[0, 2], [2, 3]]
          newRange: [[0, 2], [2, 4]]
          oldText: "llo\nworld\r\nhow"
          newText: "y there\r\ncat\nwhat"
        }]

      it "notifies ::onDidChange and ::preemptDidChange observers with the relevant details after a change", ->
        changes = []
        document.onDidChange (change) -> changes.push(['onDidChange', change])
        document.preemptDidChange (change) -> changes.push(['preemptDidChange', change])

        document.setTextInRange([[0, 2], [2, 3]], "y there\r\ncat\nwhat", normalizeLineEndings: false)
        expect(changes).toEqual [
          ['preemptDidChange', {
            oldRange: [[0, 2], [2, 3]]
            newRange: [[0, 2], [2, 4]]
            oldText: "llo\nworld\r\nhow"
            newText: "y there\r\ncat\nwhat"
          }]
          ['onDidChange', {
            oldRange: [[0, 2], [2, 3]]
            newRange: [[0, 2], [2, 4]]
            oldText: "llo\nworld\r\nhow"
            newText: "y there\r\ncat\nwhat"
          }]
        ]

      it "returns the newRange of the change", ->
        expect(document.setTextInRange([[0, 2], [2, 3]], "y there\r\ncat\nwhat"), normalizeLineEndings: false).toEqual [[0, 2], [2, 4]]

      it "clips the given range", ->
        document.setTextInRange([[-1, -1], [0, 1]], "y")
        document.setTextInRange([[0, 10], [0, 100]], "w")
        expect(document.lineForRow(0)).toBe "yellow"

      it "preserves the line endings of existing lines", ->
        document.setTextInRange([[0, 1], [0, 2]], 'o')
        expect(document.lineEndingForRow(0)).toBe '\n'
        document.setTextInRange([[1, 1], [1, 3]], 'i')
        expect(document.lineEndingForRow(1)).toBe '\r\n'

    describe "::delete(range)", ->
      it "deletes the text in the given range", ->
        document.setText("abcd")
        document.delete([[0, 1], [0, 3]])
        expect(document.getText()).toBe "ad"

  describe "history", ->
    beforeEach ->
      document.setText("hello\nworld\r\nhow are you doing?")

    it "can undo and redo changes", ->
      document.setTextInRange([[0, 5], [0, 5]], " there")
      document.setTextInRange([[1, 0], [1, 5]], "friend")
      expect(document.getText()).toBe "hello there\nfriend\r\nhow are you doing?"

      document.undo()
      expect(document.getText()).toBe "hello there\nworld\r\nhow are you doing?"

      document.undo()
      expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

      document.undo()
      expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

      document.redo()
      expect(document.getText()).toBe "hello there\nworld\r\nhow are you doing?"

      document.undo()
      expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

      document.redo()
      document.redo()
      expect(document.getText()).toBe "hello there\nfriend\r\nhow are you doing?"

      document.redo()
      expect(document.getText()).toBe "hello there\nfriend\r\nhow are you doing?"

    it "clears the redo stack upon a fresh change", ->
      document.setTextInRange([[0, 5], [0, 5]], " there")
      document.setTextInRange([[1, 0], [1, 5]], "friend")
      expect(document.getText()).toBe "hello there\nfriend\r\nhow are you doing?"

      document.undo()
      expect(document.getText()).toBe "hello there\nworld\r\nhow are you doing?"

      document.setTextInRange([[1, 3], [1, 5]], "m")
      expect(document.getText()).toBe "hello there\nworm\r\nhow are you doing?"

      document.redo()
      expect(document.getText()).toBe "hello there\nworm\r\nhow are you doing?"

      document.undo()
      expect(document.getText()).toBe "hello there\nworld\r\nhow are you doing?"

      document.undo()
      expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

    describe "transactions", ->
      beforeEach ->
        document.setTextInRange([[1, 3], [1, 5]], 'ms')
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

      it "groups all operations performed within the given function into a single undo/redo operation", ->
        document.transact ->
          document.setTextInRange([[0, 2], [0, 5]], "y")
          document.setTextInRange([[2, 13], [2, 14]], "igg")
        expect(document.getText()).toBe "hey\nworms\r\nhow are you digging?"

        # subsequent changes are not included in the transaction
        document.setTextInRange([[1, 0], [1, 0]], "little ")
        document.undo()
        expect(document.getText()).toBe "hey\nworms\r\nhow are you digging?"

        # this should undo all changes in the transaction
        document.undo()
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

        # previous changes are not included in the transaction
        document.undo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

        document.redo()
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

        # this should redo all changes in the transaction
        document.redo()
        expect(document.getText()).toBe "hey\nworms\r\nhow are you digging?"

        # this should redo the change following the transaction
        document.redo()
        expect(document.getText()).toBe "hey\nlittle worms\r\nhow are you digging?"

      it "does not push the transaction to the undo stack if it is empty", ->
        document.transact ->
        document.undo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

        document.redo()
        document.transact -> document.abortTransaction()
        document.undo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

      it "halts execution undoes all operations since the beginning of the transaction if ::abortTransaction() is called", ->
        continuedPastAbort = false
        document.transact ->
          document.setTextInRange([[0, 2], [0, 5]], "y")
          document.setTextInRange([[2, 13], [2, 14]], "igg")
          document.abortTransaction()
          continuedPastAbort = true

        expect(continuedPastAbort).toBe false

        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

        document.undo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

        document.redo()
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

        document.redo()
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

      it "preserves the redo stack until a content change occurs", ->
        document.undo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

        # no changes occur in this transaction before aborting
        document.transact ->
          document.markRange([[0, 0], [0, 5]])
          document.abortTransaction()
          document.setTextInRange([[0, 0], [0, 5]], "hey")

        document.redo()
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

        document.undo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

        document.transact ->
          document.setTextInRange([[0, 0], [0, 5]], "hey")
          document.abortTransaction()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

        document.redo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

      it "allows nested transactions", ->
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

        document.transact ->
          document.setTextInRange([[0, 2], [0, 5]], "y")
          document.transact ->
            document.setTextInRange([[2, 13], [2, 14]], "igg")
            document.setTextInRange([[2, 18], [2, 19]], "'")
          expect(document.getText()).toBe "hey\nworms\r\nhow are you diggin'?"
          document.undo()
          expect(document.getText()).toBe "hey\nworms\r\nhow are you doing?"
          document.redo()
          expect(document.getText()).toBe "hey\nworms\r\nhow are you diggin'?"

        document.undo()
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

        document.redo()
        expect(document.getText()).toBe "hey\nworms\r\nhow are you diggin'?"

        document.undo()
        document.undo()
        expect(document.getText()).toBe "hello\nworld\r\nhow are you doing?"

      it "groups adjacent transactions within each other's grouping intervals", ->
        now = 0
        spyOn(Date, 'now').and.callFake -> now

        document.transact 100, -> document.setTextInRange([[0, 2], [0, 5]], "y")
        now += 100
        document.transact 200, -> document.setTextInRange([[0, 3], [0, 3]], "yy")
        now += 200
        document.transact 200, -> document.setTextInRange([[0, 5], [0, 5]], "yy")

        # not grouped because the previous transaction's grouping interval
        # is only 200ms and we've advanced 300ms
        now += 300
        document.transact 300, -> document.setTextInRange([[0, 7], [0, 7]], "!!")

        expect(document.getText()).toBe "heyyyyy!!\nworms\r\nhow are you doing?"
        document.undo()
        expect(document.getText()).toBe "heyyyyy\nworms\r\nhow are you doing?"
        document.undo()
        expect(document.getText()).toBe "hello\nworms\r\nhow are you doing?"

    describe "checkpoints", ->
      beforeEach ->
        document.setText("")

      describe "::revertToCheckpoint(checkpoint)", ->
        it "undoes all changes following the checkpoint", ->
          document.append("hello")
          checkpoint = document.createCheckpoint()

          document.transact ->
            document.append("\n")
            document.append("world")

          checkpoint2 = document.createCheckpoint()

          document.append("\n")
          document.append("how are you?")

          result = document.revertToCheckpoint(checkpoint)
          expect(result).toBe(true)
          expect(document.getText()).toBe("hello")

          return

          result = document.revertToCheckpoint(checkpoint2)
          expect(result).toBe(false)

          document.undo()
          expect(document.getText()).toBe("")

          document.redo()
          expect(document.getText()).toBe("hello")

      describe "::groupChangesSinceCheckpoint(checkpoint)", ->
        it "combines all changes since the checkpoint into a single transaction", ->
          document.append("one\n")
          checkpoint = document.createCheckpoint()
          document.append("two\n")
          checkpoint2 = document.createCheckpoint()
          document.transact ->
            document.append("three\n")
            document.append("four")

          result = document.groupChangesSinceCheckpoint(checkpoint)
          expect(result).toBe true

          expect(document.getText()).toBe """
            one
            two
            three
            four
          """

          result = document.groupChangesSinceCheckpoint(checkpoint2)
          expect(result).toBe false

          document.undo()
          expect(document.getText()).toBe("one\n")

          document.redo()
          expect(document.getText()).toBe """
            one
            two
            three
            four
          """

        it "skips any later checkpoints when grouping changes", ->
          document.append("one\n")
          checkpoint = document.createCheckpoint()
          document.append("two\n")
          checkpoint2 = document.createCheckpoint()
          document.append("three")

          document.groupChangesSinceCheckpoint(checkpoint)
          expect(document.revertToCheckpoint(checkpoint2)).toBe(false)

          expect(document.getText()).toBe """
            one
            two
            three
          """

          document.undo()
          expect(document.getText()).toBe("one\n")

          document.redo()
          expect(document.getText()).toBe """
            one
            two
            three
          """

      it "skips checkpoints when undoing", ->
        document.append("hello")
        document.createCheckpoint()
        document.createCheckpoint()
        document.createCheckpoint()
        document.undo()
        expect(document.getText()).toBe("")

      it "preserves checkpoints across undo and redo", ->
        document.append("hello\n")
        checkpoint = document.createCheckpoint()
        document.undo()
        expect(document.getText()).toBe("")
        document.redo()
        expect(document.getText()).toBe("hello\n")
        document.append("world")

        expect(document.revertToCheckpoint(checkpoint)).toBe true
        expect(document.getText()).toBe("hello\n")

      it "handles checkpoints created when there have been no changes", ->
        document = new TextDocument
        checkpoint1 = document.createCheckpoint()
        checkpoint2 = document.createCheckpoint()
        document.undo()
        document.append("hello")
        expect(document.revertToCheckpoint(checkpoint2)).toBe true
        expect(document.revertToCheckpoint(checkpoint1)).toBe true
        expect(document.getText()).toBe("")

  describe "file details", ->
    describe "encoding", ->
      it "uses utf8 by default", ->
        expect(document.getEncoding()).toBe "utf8"

      it "allows the encoding to be set with ::setEncoding(encoding)", ->
        document.setEncoding("ascii")
        expect(document.getEncoding()).toBe "ascii"
