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
    @redoStack.push(new Checkpoint(redoMetadata))
    {metadata, changes} = @popChanges(@undoStack, @redoStack)
    {metadata, changes: changes.map(@invertChange)}

  popRedoStack: ->
    @popChanges(@redoStack, @undoStack)

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

  popChanges: (fromStack, toStack) ->
    result = {metadata: null, changes: []}

    firstChangeIndex = null
    for entry, i in fromStack by -1
      if entry instanceof Checkpoint
        break if firstChangeIndex?
      else
        firstChangeIndex = i

    if firstChangeIndex?
      poppedChanges = fromStack.splice(firstChangeIndex)
      for change in poppedChanges by -1
        toStack.push(change)
        result.changes.push(change) unless change instanceof Checkpoint

      poppedCheckpoint = fromStack.pop()
      toStack.push(poppedCheckpoint)
      result.metadata = poppedCheckpoint.metadata

    result

  invertChange: ({oldRange, newRange, oldText, newText}) ->
    Object.freeze({
      oldRange: newRange
      newRange: oldRange
      oldText: newText
      newText: oldText
    })
