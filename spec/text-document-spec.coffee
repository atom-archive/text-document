Point = require "../src/point"
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
