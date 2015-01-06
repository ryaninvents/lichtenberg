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

  instrumentIfStatement: (stmt) ->
    if stmt.consequent? and stmt.consequent.type isnt 'BlockExpression'
      stmt.consequent = @instrument @toBlock stmt.consequent
    if stmt.alternate? and stmt.alternate.type isnt 'BlockExpression'
      stmt.alternate = @instrument @toBlock stmt.alternate
    stmt

  instrumentReturnStatement: (stmt) ->
    @instrumentExpressionStatement.apply @, arguments

  instrumentVariableDeclaration: (stmt) ->
    @instrumentExpressionStatement.apply @, arguments

  # Full file.
  instrumentProgram: (pgm) ->
    pgm.instrumentation = _.flatten(pgm.body.filter (node) -> node.instrumentation?.length
      .map (node) -> node.instrumentation
    )
    expects = pgm.instrumentation.map (instrument) => @lichtCall instrument, func: 'expect'
    expects = expects.filter (line) -> line._props.range and ((line._props?.type?.match /Function|(Statement|Declaration)$/))
    expects = _.uniq expects, (x) -> "#{x._props?.range?[0]}:#{x._props?.range?[1]}"
    try
      expects = expects.sort (a, b) ->
        [a, b] = [a._props.range, b._props.range]
        switch
          when a[0] < b[0]
            -1
          when a[0] > b[0]
            1
          when a[1] < b[1]
            1
          when a[1] > b[1]
            -1
          else
            0
    catch e
      throw e
    pgm.body = _.flatten(expects.concat(pgm.body))
    pgm
