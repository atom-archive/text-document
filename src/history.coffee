class Checkpoint
  counter = 1

  constructor: (metadata, internal) ->
    @id = counter++
    @internal = internal ? false
    @metadata = metadata

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
    @undoStack.push(change)
    @redoStack.length = 0

  popUndoStack: (metadata) ->
    if (checkpointIndex = @getBoundaryCheckpointIndex(@undoStack))?
      @redoStack.push(new Checkpoint(metadata, true))
      result = @popChanges(@undoStack, @redoStack, checkpointIndex)
      result.changes = result.changes.map(@invertChange)
      result

  popRedoStack: (metadata) ->
    if (checkpointIndex = @getBoundaryCheckpointIndex(@redoStack))?
      @undoStack.push(new Checkpoint(metadata, true))
      @popChanges(@redoStack, @undoStack, checkpointIndex)

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

  getBoundaryCheckpointIndex: (stack) ->
    result = null
    hasSeenChanges = false
    for entry, i in stack by -1
      if entry instanceof Checkpoint
        result = i if hasSeenChanges
      else
        hasSeenChanges = true
        break if result?
    result

  popChanges: (fromStack, toStack, checkpointIndex) ->
    changes = []
    metadata = fromStack[checkpointIndex].metadata
    for entry in fromStack.splice(checkpointIndex) by -1
      isCheckpoint = entry instanceof Checkpoint
      toStack.push(entry) unless isCheckpoint and entry.internal
      changes.push(entry) unless isCheckpoint
    {changes, metadata}

  invertChange: ({oldRange, newRange, oldText, newText}) ->
    Object.freeze({
      oldRange: newRange
      newRange: oldRange
      oldText: newText
      newText: oldText
    })
