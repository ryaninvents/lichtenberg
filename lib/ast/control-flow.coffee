module.exports = (opt) ->

  # Block statement: `{foo = bar; alert('baz')}`
  instrumentBlockStatement: (block) ->
    @instrument block, 'body'

  # `break` keyword; TODO
  instrumentBreakStatement: (brk) -> brk

  # `catch` clause
  # TODO enable branch coverage over this
  instrumentCatchClause: (clause) ->
    @instrument clause, 'param', 'body'

  # `continue` keyword; TODO
  instrumentContinueStatement: (c) -> c

  # Do/while loop.
  instrumentDoWhileStatement: (dwLoop) ->
    @instrument dwLoop, 'body', 'test'

  # `debugger` keyword supported in some environments
  instrumentDebuggerStatement: (dbg) -> dbg

  # No-op
  # TODO this should actually be instrumented
  instrumentEmptyStatement: (noop) -> noop

  # Statement consisting of a single expression
  instrumentExpressionStatement: (expr) ->
    @instrument expr, 'expression'
    if expr.instrumentation.length is 9
      console.log expr.instrumentation
    [@lichtCall(expr), expr]

  # Standard c-style for loop
  instrumentForStatement: (fLoop)->
    @instrument fLoop, 'init', 'test', 'update', 'body'

  # For/in comprehension
  instrumentForInStatement: (forIn) ->
    @instrument forIn, 'left', 'right', 'body'

  # If/then/else
  instrumentIfStatement: (ifThen) ->
    @instrument ifThen, 'test', 'consequent', 'alternate'

  # Labeled statement such as `foo: x = 7;`
  # TODO this needs instrumentation on it
  instrumentLabeledStatement: (lbl) ->
    @instrument lbl, 'label', 'body'

  # Full file.
  # # TODO inject collected instrumentation into the top as `expect` statements
  instrumentProgram: (pgm) ->
    @instrument pgm, 'body'
    console.log 'pgm Ins', pgm.instrumentation
    expects = pgm.instrumentation.map (instrument) => @lichtCall instrument, func: 'expect'
    pgm.body = expects
    console.log expects
    pgm

  # Particular case of a switch/case
  instrumentSwitchCase: (sCase) ->
    @instrument sCase, 'test', 'consequent'

  # Throw statement: `throw e;`
  instrumentThrowStatement: (thrw) ->
    @instrument thrw, 'argument'

  # Try/catch statement: `try{}catch(e){}`
  instrumentTryStatement: (tryCatch) ->
    @instrument tryCatch, 'block', 'guardedHandlers', 'handlers'

  # While loop
  instrumentWhileStatement: (wLoop) ->
    @instrument wLoop, 'test', 'body'

  # With block: `with(foo){}`
  instrumentWithStatement: (w) ->
    @instrument w, 'object', 'body'
