Point = require "./point"
Range = require "./range"

BRANCHING_FACTOR = 3

class Node
  constructor: (@children) ->
    @ids = new Set
    @extent = Point.zero()
    for child in @children
      @extent = @extent.traverse(child.extent)
      addAllToSet(@ids, child.ids)

  insert: (ids, start, end) ->
    # Insert the given id into all children that intersect the given range.
    # Take the intersection of the given range and the child's range when
    # inserting into each child.
    rangeIsEmpty = start.compare(end) is 0
    childEnd = Point.zero()
    i = 0
    while i < @children.length
      child = @children[i++]
      childStart = childEnd
      childEnd = childStart.traverse(child.extent)

      switch childStart.compare(end)
        when -1 then childFollowsRange = false
        when 0  then childFollowsRange = not child.hasEmptyLeftmostLeaf() and not rangeIsEmpty
        when 1  then childFollowsRange = true
      break if childFollowsRange

      switch childEnd.compare(start)
        when -1 then childPrecedesRange = true
        when 0  then childPrecedesRange = not child.hasEmptyRightmostLeaf()
        when 1  then childPrecedesRange = false
      continue if childPrecedesRange

      relativeStart = Point.max(Point.zero(), start.traversalFrom(childStart))
      relativeEnd = Point.min(child.extent, end.traversalFrom(childStart))
      if newChildren = child.insert(ids, relativeStart, relativeEnd)
        @children.splice(i - 1, 1, newChildren...)
        i += newChildren.length - 1

    if @children.length > BRANCHING_FACTOR
      splitIndex = Math.ceil(@children.length / BRANCHING_FACTOR)
      [new Node(@children.slice(0, splitIndex)), new Node(@children.slice(splitIndex))]
    else
      addAllToSet(@ids, ids)
      return

  delete: (id) ->
    if @ids.has(id)
      @ids.delete(id)
      i = 0
      while i < @children.length
        @children[i].delete(id)
        if @children[i - 1]?.shouldMergeWith(@children[i])
          @children.splice(i - 1, 2, @children[i - 1].merge(@children[i]))
        else
          i++

  hasEmptyRightmostLeaf: ->
    @children[@children.length - 1].hasEmptyRightmostLeaf()

  hasEmptyLeftmostLeaf: ->
    @children[0].hasEmptyLeftmostLeaf()

  splice: (position, oldExtent, newExtent, excludedIds) ->
    childStart = Point.zero()
    oldExtentEmpty = oldExtent.isZero()
    for child in @children
      childEnd = childStart.traverse(child.extent)

      if remainderToDelete?
        break unless remainderToDelete.isPositive()
        remainderToDelete = child.splice(Point.zero(), remainderToDelete, Point.zero())
        continue

      comparison = childEnd.compare(position)
      if comparison > 0 or (comparison is 0 and oldExtentEmpty and child.hasEmptyRightmostLeaf())
        remainderToDelete = child.splice(position.traversalFrom(childStart), oldExtent, newExtent, excludedIds)

      childStart = childEnd

    @extent = @extent
      .traverse(newExtent.traversalFrom(oldExtent))
      .traverse(remainderToDelete)
    remainderToDelete

  shouldMergeWith: (other) ->
    @children.length + other.children.length <= BRANCHING_FACTOR

  merge: (other) ->
    new Node(@children.concat(other.children))

  getStart: (id) ->
    return unless @ids.has(id)
    childStart = Point.zero()
    for child in @children
      if startRelativeToChild = child.getStart(id)
        return childStart.traverse(startRelativeToChild)
      childStart = childStart.traverse(child.extent)
    return

  getEnd: (id) ->
    return unless @ids.has(id)
    childStart = Point.zero()
    for child in @children
      if endRelativeToChild = child.getEnd(id)
        end = childStart.traverse(endRelativeToChild)
      else if end?
        break
      childStart = childStart.traverse(child.extent)
    end

  findContaining: (point, set) ->
    childStart = Point.zero()
    for child in @children
      childEnd = childStart.traverse(child.extent)
      if point.compare(childEnd) <= 0
        child.findContaining(point.traversalFrom(childStart), set)
      break if childEnd.compare(point) > 0
      childStart = childEnd

  findStartingAt: (point, set) ->
    childStart = Point.zero()
    for child, i in @children
      childEnd = childStart.traverse(child.extent)
      if point.compare(childEnd) < 0
        if point.compare(childStart) is 0
          child.findStartingAt(Point.zero(), set)
          if previousChild = @children[i - 1]
            alreadyStartedIds = new Set
            previousChild.findContaining(previousChild.extent, alreadyStartedIds)
            deleteAllFromSet(set, alreadyStartedIds)
        else
          child.findStartingAt(point.traversalFrom(childStart), set)
      break if childEnd.compare(point) > 0
      childStart = childEnd

  findEndingAt: (point, set) ->
    childStart = Point.zero()
    for child, i in @children
      childEnd = childStart.traverse(child.extent)
      comparison = point.compare(childEnd)
      if comparison < 0
        child.findEndingAt(point.traversalFrom(childStart), set)
      else if comparison is 0
        child.findEndingAt(child.extent, set)

        if nextChild = @children[i + 1]
          continuingIds = new Set
          nextChild.findContaining(Point.zero(), continuingIds)
          deleteAllFromSet(set, continuingIds)
      break if childEnd.compare(point) > 0
      childStart = childEnd

  toString: (indentLevel=0) ->
    indent = ""
    indent += " " for i in [0...indentLevel] by 1

    ids = []
    values = @ids.values()
    until (next = values.next()).done
      ids.push(next.value)

    """
      #{indent}Node #{@extent} (#{ids.join(" ")})
      #{@children.map((c) -> c.toString(indentLevel + 2)).join("\n")}
    """

class Leaf
  constructor: (@extent, @ids) ->

  insert: (ids, start, end) ->
    # If the given range matches the start and end of this leaf exactly, add
    # the given id to this leaf. Otherwise, split this leaf into up to 3 leaves,
    # adding the id to the portion of this leaf that intersects the given range.
    if start.isZero() and end.compare(@extent) is 0
      addAllToSet(@ids, ids)
      return
    else
      newIds = new Set(@ids)
      addAllToSet(newIds, ids)
      newLeaves = []
      newLeaves.push(new Leaf(start, new Set(@ids))) if start.isPositive()
      newLeaves.push(new Leaf(end.traversalFrom(start), newIds))
      newLeaves.push(new Leaf(@extent.traversalFrom(end), new Set(@ids))) if @extent.compare(end) > 0
      newLeaves

  delete: (id) ->
    @ids.delete(id)

  splice: (position, spliceOldExtent, spliceNewExtent, excludedIds) ->
    deleteAllFromSet(@ids, excludedIds) if excludedIds?
    myOldExtent = @extent
    spliceOldEnd = position.traverse(spliceOldExtent)
    spliceNewEnd = position.traverse(spliceNewExtent)
    spliceDelta = spliceNewExtent.traversalFrom(spliceOldExtent)

    if spliceOldEnd.compare(@extent) > 0
      # If the splice ends after this leaf node, this leaf should end at
      # the end of the splice.
      @extent = spliceNewEnd
    else
      # Otherwise, this leaf contains the splice, its size should be adjusted
      # by the delta.
      @extent = Point.max(Point.zero(), @extent.traverse(spliceDelta))

    # How does the splice to this leaf's extent compare to the global splice in
    # the tree's extent implied by the splice? If this leaf grew too much or didn't
    # shrink enough, we may need to shrink subsequent leaves.
    @extent.traversalFrom(myOldExtent).traversalFrom(spliceDelta)

  shouldMergeWith: (other) ->
    setEqual(@ids, other.ids)

  merge: (other) ->
    new Leaf(@extent.traverse(other.extent), new Set(@ids))

  getStart: (id) ->
    Point.zero() if @ids.has(id)

  getEnd: (id) ->
    @extent if @ids.has(id)

  hasEmptyRightmostLeaf: ->
    @extent.isZero()

  hasEmptyLeftmostLeaf: ->
    @extent.isZero()

  findContaining: (point, set) ->
    addAllToSet(set, @ids)

  findStartingAt: (point, set) ->
    addAllToSet(set, @ids) if point.isZero()

  findEndingAt: (point, set) ->
    addAllToSet(set, @ids) if point.compare(@extent) is 0

  toString: (indentLevel=0) ->
    indent = ""
    indent += " " for i in [0...indentLevel] by 1

    ids = []
    values = @ids.values()
    until (next = values.next()).done
      ids.push(next.value)

    "#{indent}Leaf #{@extent} (#{ids.join(" ")})"

module.exports =
class MarkerIndex
  constructor: ->
    @exclusiveIds = new Set
    @rootNode = new Leaf(Point.infinity(), new Set)

  insert: (id, start, end) ->
    ids = new Set
    ids.add(id)
    @rootNode.findContaining(start, ids) if start.compare(end) is 0
    if splitNodes = @rootNode.insert(ids, start, end)
      @rootNode = new Node(splitNodes)

  delete: (id) ->
    @rootNode.delete(id)

  splice: (position, oldExtent, newExtent) ->
    if oldExtent.isZero()
      startingIds = new Set
      @rootNode.findStartingAt(position, startingIds)
      endingIds = new Set
      @rootNode.findEndingAt(position, endingIds)
      addAllToSet(startingIds, endingIds)
      boundaryIds = startingIds

      if boundaryIds.size > 0
        if splitNodes = @rootNode.insert(boundaryIds, position, position)
          @rootNode = new Node(splitNodes)

        excludedIds = new Set
        boundaryIds.forEach (id) =>
          excludedIds.add(id) if @exclusiveIds.has(id)

    @rootNode.splice(position, oldExtent, newExtent, excludedIds)

  setExclusive: (id, isExclusive) ->
    if isExclusive
      @exclusiveIds.add(id)
    else
      @exclusiveIds.delete(id)

  getRange: (id) ->
    if start = @getStart(id)
      Range(start, @getEnd(id))

  getStart: (id) ->
    @rootNode.getStart(id)

  getEnd: (id) ->
    @rootNode.getEnd(id)

  findContaining: (start, end) ->
    containing = new Set
    @rootNode.findContaining(start, containing)
    if end? and end.compare(start) isnt 0
      containingEnd = new Set
      @rootNode.findContaining(end, containingEnd)
      containing.forEach (id) -> containing.delete(id) unless containingEnd.has(id)
    containing

  findIntersecting: (start, end) ->
    intersecting = new Set
    @rootNode.findContaining(start, intersecting)
    if end? and end.compare(start) isnt 0
      @rootNode.findContaining(end, intersecting)
    intersecting

  findStartingAt: (point) ->
    result = new Set
    @rootNode.findStartingAt(point, result)
    result

  findEndingAt: (point) ->
    result = new Set
    @rootNode.findEndingAt(point, result)
    result

setEqual = (a, b) ->
  return false unless a.size is b.size
  iterator = a.values()
  until (next = iterator.next()).done
    return false unless b.has(next.value)
  true

deleteAllFromSet = (set, valuesToRemove) ->
  valuesToRemove.forEach (value) -> set.delete(value)

addAllToSet = (set, valuesToAdd) ->
  valuesToAdd.forEach (value) -> set.add(value)
