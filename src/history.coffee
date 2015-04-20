counter = 1

class Checkpoint
  constructor: (@metadata) ->
    @id = counter++

module.exports =
class History
  constructor: ->
    @undoStack = []
    @redoStack = []

  createCheckpoint: (metadata) ->
    checkpoint = new Checkpoint(metadata)
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

  popUndoStack: (redoMetadata) ->
    if firstChangeIndex = @firstChangeIndex(@undoStack)
      @redoStack.push(new Checkpoint(redoMetadata))
      result = @popChanges(@undoStack, @redoStack, firstChangeIndex)
      result.changes = result.changes.map(@invertChange)
      result

  popRedoStack: ->
    if firstChangeIndex = @firstChangeIndex(@redoStack)
      @popChanges(@redoStack, @undoStack, firstChangeIndex)

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

  ###
  Section: Private
  ###

  firstChangeIndex: (stack) ->
    firstChangeIndex = null
    for entry, i in stack by -1
      if entry instanceof Checkpoint
        break if firstChangeIndex?
      else
        firstChangeIndex = i
    firstChangeIndex

  popChanges: (fromStack, toStack, firstChangeIndex) ->
    changes = []
    for entry in fromStack.splice(firstChangeIndex) by -1
      toStack.push(entry)
      changes.push(entry) unless entry instanceof Checkpoint
    checkpoint = fromStack.pop()
    toStack.push(checkpoint)
    {changes, metadata: checkpoint.metadata}

  invertChange: ({oldRange, newRange, oldText, newText}) ->
    Object.freeze({
      oldRange: newRange
      newRange: oldRange
      oldText: newText
      newText: oldText
    })
