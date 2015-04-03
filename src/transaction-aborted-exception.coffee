module.exports =
class TransactionAbortedException extends Error
  constructor: (@transaction) ->
