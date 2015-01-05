escodegen = require 'escodegen'
_ = require 'lodash'

dbg = (node) ->
  console.log("================ #{node.type} ================\n\n", node.instrumentation.map (x) =>
      escodegen.generate @lichtCall x, func: 'debug'
    .join("\n----------------------------------------------\n")
  )

module.exports = (opt) ->
  # Statement consisting of a single expression
  instrumentExpressionStatement: (expr) ->
    expr.instrumentation.push expr
    [@lichtCall(expr, name: 'statement'), expr]
    #@lichtCall expr, name: 'statement'

  instrumentBlockStatement: (block) ->
    block.instrumentation = _.flatten block.body.map (node) -> node.instrumentation
    block

  instrumentIfStatement: (stmt) ->
    if stmt.consequent? and stmt.consequent.type isnt 'BlockExpression'
      stmt.consequent = @instrument @toBlock stmt.consequent
    if stmt.alternate? and stmt.alternate.type isnt 'BlockExpression'
      stmt.alternate = @instrument @toBlock stmt.alternate
    stmt

  instrumentReturnStatement: (stmt) ->
    @instrumentExpressionStatement.apply @, arguments

  # Full file.
  instrumentProgram: (pgm) ->
    pgm.instrumentation = _.flatten(pgm.body.filter (node) -> node.instrumentation?.length
      .map (node) -> node.instrumentation
    )
    expects = pgm.instrumentation.map (instrument) => @lichtCall instrument, func: 'expect'
    expects = expects.filter (line) -> line._props.range and line._props?.type in [
        'ExpressionStatement'
        'FunctionExpression'
        'FunctionDeclaration'
        'ArrowFunctionExpression'
      ]
    expects = _.uniq expects, (x) -> "#{x._props?.range?[0]}:#{x._props?.range?[1]}"
    try
      expects = expects.sort (a, b) ->
        if a._props.range[0] < b._props.range[0]
          -1
        else if a._props.range[0] > b._props.range[0]
          1
        else if a._props.range[1] < b._props.range[1]
          1
        else if a._props.range[1] > b._props.range[1]
          -1
        else
          0
    catch e
      # console.log expects
      throw e
    pgm.body = _.flatten expects.concat pgm.body
    pgm
