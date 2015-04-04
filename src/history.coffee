counter = 1

class Checkpoint
  constructor: ->
    @id = counter++

module.exports =
class History
  constructor: ->
    @undoStack = []
    @redoStack = []

  createCheckpoint: ->
    checkpoint = new Checkpoint
    @undoStack.push(checkpoint)
    checkpoint

  groupChangesSinceCheckpoint: (checkpoint) ->
    return false if @undoStack.lastIndexOf(checkpoint) is -1
    for entry, i in @undoStack by -1
      break if entry is checkpoint
      @undoStack.splice(i, 1) if entry instanceof Checkpoint
    true

  applyCheckpointGroupingInterval: (checkpoint, groupingInterval) ->
    return if groupingInterval is 0

    now = Date.now()

    groupedCheckpoint = null
    checkpointIndex = @undoStack.lastIndexOf(checkpoint)

    for i in [checkpointIndex - 1..0] by -1
      entry = @undoStack[i]
      if entry instanceof Checkpoint
        if (entry.timestamp + Math.min(entry.groupingInterval, groupingInterval)) >= now
          @undoStack.splice(checkpointIndex, 1)
          groupedCheckpoint = entry
        else
          groupedCheckpoint = checkpoint
        break

    groupedCheckpoint.timestamp = now
    groupedCheckpoint.groupingInterval = groupingInterval

  pushChange: (change) ->
    @undoStack.push(new Checkpoint, change)
    @redoStack.length = 0

  popUndoStack: ->
    firstChangeIndex = null
    for entry, i in @undoStack by -1
      if entry instanceof Checkpoint
        break if firstChangeIndex?
      else
        firstChangeIndex = i

    return [] unless firstChangeIndex?

    invertedChanges = []
    undoneEntries = @undoStack.splice(firstChangeIndex, @undoStack.length - firstChangeIndex)
    for entry in undoneEntries by -1
      @redoStack.push(entry)
      invertedChanges.push(@invertChange(entry)) unless entry instanceof Checkpoint
    invertedChanges

  popRedoStack: ->
    changes = []
    while entry = @redoStack.pop()
      @undoStack.push(entry)
      if entry instanceof Checkpoint
        break if changes.length > 0
      else
        changes.push(entry)
    changes

  truncateUndoStack: (checkpoint) ->
    checkpointIndex = @undoStack.lastIndexOf(checkpoint)
    return false if checkpointIndex is -1

    invertedChanges = []
    while entry = @undoStack.pop()
      if entry instanceof Checkpoint
        break if entry is checkpoint
      else
        invertedChanges.push(@invertChange(entry))
    invertedChanges

  clearRedoStack: ->
    @redoStack.length = 0

  invertChange: ({oldRange, newRange, oldText, newText}) ->
    Object.freeze({
      oldRange: newRange
      newRange: oldRange
      oldText: newText
      newText: oldText
    })
