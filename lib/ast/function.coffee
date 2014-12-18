getFunctionName = (f) -> f.id?.name or '«anonymous function»'

module.exports = (opt) ->
  # Arrow function `x => x*x`
  instrumentArrowFunctionExpression: (func) ->
    func.body = @toBlock func.body
    func = @instrument func, 'params', 'defaults', 'body', 'rest'
    func.body.body.unshift @lichtCall func, name: getFunctionName
    func.instrumentation.push func
    func

  # Function declaration `function foo(){}`
  instrumentFunctionDeclaration: (func) ->
    func.body = @toBlock func.body
    i = @instrument func, 'id', 'params', 'defaults', 'body', 'rest'
    func.body.body.unshift @lichtCall func, name: getFunctionName
    func.instrumentation.push func
    func

  # Function expression `function(){}`
  instrumentFunctionExpression: (func) ->
    func.body = @toBlock func.body
    @instrument func, 'id', 'params', 'defaults', 'body', 'rest'
    func.body.body.unshift @lichtCall func, name: getFunctionName
    func.instrumentation.push func
    func
