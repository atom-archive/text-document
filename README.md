


# text-document [![Build Status](https://travis-ci.org/atom/text-document.svg?branch=master)](https://travis-ci.org/atom/text-document)

**Hey there, this library isn't being developed lately, but much of what we learned building it is being introduced into Atom incrementally. We decided it wasn't necessarily to replace this large a piece of the system at once, but it was good to get a chance to think for a while with a clean slate.**

------

This library will replace TextBuffer, TokenizedBuffer, and DisplayBuffer in Atom with API-compatible alternatives that perform better and consume vastly less memory.

## Exported Classes

### TextDocument

This class will be a drop-in replacement `TextBuffer` and implement its API. We should build our tests by example (or outright copying) from TextBuffer, cleaning up their structure but leaving the API otherwise intact.

Instances will house a `BufferLayer` and a `TransformLayer` based on `LinesTransform`, which they will use as primitives to expose their API. The `BufferLayer` will store a read-only portion of the file being edited in memory for fast access, referencing a temporary copy of the file on disk for content exceeding what we're willing to store. The lines transform layer stores the mapping from two dimensions (rows/columns) to one dimension (character offsets in the file).

### ScopedTextDocument

This class will replace `TokenizedBuffer`, an Atom private class, implementing enough of its API to keep existing references working. We can deviate from the existing API here since this class is private, but we should have a good reason. Tests should be based on existing tests for `TokenizedBuffer`, where the APIs being tested are still relevant.

Instances will house a `NestedWordLayer`, which uses Atom's existing parser to insert open and close tags for scopes into the content stream. For layers that aren't interested in syntax, these tags will ride along with the content invisibly, consuming no logical space, but scope information will be accessible to subsequent layers if they wish to make scope-based decisions.

We should not replicate the `TokenizedLine` API in this layer, instead relying on a shim in Atom to wrap instances of `TextContent` and present them with the same token-based API as currently exists. Ultimately, we should aim to transition away from `TokenizedLine` in Atom and use the tagged `TextContent` stream instead.

### TextDisplayDocument

This class will replace `DisplayBuffer`, another Atom private class. It will perform all transformations needed to prepare content for display, including soft wrap, folds, hard tab expansion, soft tab clipping, and paired Unicode character collapsing. Instances will contain a stacked series of transform layers to implement these operations. Again, we should default to matching the `DisplayBuffer` API where appropriate.

## Internal Structures

The three public classes listed above will be implemented in terms of lower-level primitives. Each of these objects exposes an iterator-based interface that can be used to seek and read at a given location, making them optimal for streaming operations. In all layers, we maintain an *active region*, which is based on, but not necessarily identical to, the region of the file that is currently visible on screen.

### FileLayer

This is the lowest layer, managing interaction with the file system. Its iterator is based on Node's built-in file handles. If the file being edited is too large to load into memory based on the active region, this layer will also manage a temporary copy of the file on disk.

### BufferLayer

This layer builds on `FileLayer`, storing a portion of the file in memory based on the active region. When the active region changes, this layer flushes and loads content from the layer below accordingly. This layer can also be used above specific transform layers to cache their content. If used in this capacity, it will need to handle change events from the underlying layer.

### TransformLayer

Transform layers can be instantiated with different transform implementations to implement things like tab expansion and soft wrap. They also store a region map which indexes the spatial correspondence between input and target coordinates. In addition to performing transforms in an initial streaming fashion, transform layers also transform and re-emit change events from the layer below.

### Patch

This class indexes the spatial correspondence between two layers. Each transform layer uses a region map to efficiently translate positions between its input and target coordinate spaces. It is also used by the `BufferLayer` to store in-memory content.

It's currently implemented as an array of *regions*, with each region having a *input extent*, *target extent*, and *content*. To find an input position corresponding to a target position or vice versa, we simply traverse the array, maintaining the total distance traversed in either dimension. To make this class efficient, this linear data structure will need to be replaced with a tree, possibly a counted B+ tree or some persistent equivalent.

## Markers

Layers will also maintain a marker index. By implementing this index as a counted balanced tree, the impact of mutations on markers can be processed in logarithmic time as a function of the number of markers. We'll need to move away from emitting events on individual markers to realize the savings, however.

## Tasks

The basic structure is in place, but there's still a lot to be done.

* [x] Implement position translation between layers
* [ ] Index position translation in `TransformLayer` using a `Patch`. The `Patch` API will need to be extended a bit to achieve this.
* [ ] Implement marker API based on an efficient index
* [ ] Implement `ScopedTextDocument` and create a `TextContent` data type that can intersperse scope start and end tags with strings of normal content.
* [ ] Add temp file handling to `FileLayer`
* [ ] Add history tracking with transactions, undo, redo, etc.

## Questions

* What about using immutable data structures for our region map and marker index? That might make undo easier to implement, but it needs to be super fast.
* For the future: Can we implement some sort of multi-version concurrency control to keep the content of the buffer stable for the lifetime of a transaction while performing I/O asynchronously?
