module.exports =
class History
  constructor: ->
    @undoStack = []
    @redoStack = []

  pushChange: (change) ->
    @undoStack.push(change)
    @redoStack.length = 0

  popUndoStack: ->
    if change = @undoStack.pop()
      @redoStack.push(change)
      @invertChange(change)

  popRedoStack: ->
    if change = @redoStack.pop()
      @undoStack.push(change)
      change

  invertChange: ({oldRange, newRange, oldText, newText}) ->
    Object.freeze({
      oldRange: newRange
      newRange: oldRange
      oldText: newText
      newText: oldText
    })
