TransactionAbortedException = require './transaction-aborted-exception'

module.exports =
class History
  transactionDepth: 0
  currentTransaction: null

  constructor: ->
    @undoStack = []
    @redoStack = []

  transact: (groupingInterval, fn) ->
    if @currentTransaction?
      fn()
    else
      @beginTransaction(groupingInterval)
      result = fn()
      @commitCurrentTransaction()
      result

  abortTransaction: ->
    exception = new TransactionAbortedException(@invertTransaction(@currentTransaction))
    @transactionDepth = 0
    @currentTransaction = null
    throw exception

  beginTransaction: (groupingInterval=0) ->
    if @transactionDepth is 0
      @currentTransaction = {groupingInterval, changes: []}
    @transactionDepth++

  commitCurrentTransaction: ->
    throw new Error("No transaction started") unless @currentTransaction?
    @transactionDepth--
    if @transactionDepth is 0
      transaction = @currentTransaction
      @currentTransaction = null
      if transaction.changes.length > 0
        @undoStack.push(transaction)

  pushChange: (change) ->
    @redoStack.length = 0
    if @currentTransaction?
      @currentTransaction.changes.push(change)
    else
      @beginTransaction()
      @pushChange(change)
      @commitCurrentTransaction()

  popUndoStack: ->
    if transaction = @undoStack.pop()
      @redoStack.push(transaction)
      @invertTransaction(transaction)

  popRedoStack: ->
    if change = @redoStack.pop()
      @undoStack.push(change)
      change

  invertTransaction: (transaction) ->
    Object.freeze({
      groupingInterval: 0
      changes: transaction.changes.reverse().map(@invertChange)
    })

  invertChange: ({oldRange, newRange, oldText, newText}) ->
    Object.freeze({
      oldRange: newRange
      newRange: oldRange
      oldText: newText
      newText: oldText
    })
