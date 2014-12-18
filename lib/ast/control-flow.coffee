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
    [@lichtCall(expr), expr]
    expr

  instrumentBlockStatement: (block) ->
    block.instrumentation = _.flatten block.body.map (node) -> node.instrumentation

  # Full file.
  instrumentProgram: (pgm) ->
    pgm.instrumentation = _.flatten(pgm.body.filter (node) -> node.instrumentation?.length
      .map (node) -> node.instrumentation
    )
    expects = pgm.instrumentation.map (instrument) => @lichtCall instrument, func: 'expect'
    # console.log expects
    expects = _.uniq expects, (x) -> "#{x._props?.range?[0]}:#{x._props?.range?[1]}"
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
    pgm.body = expects.concat pgm.body
    #console.log expects
    pgm
