module.exports = (opt) ->

  # Assignment expression: `x = 7`.
  instrumentAssignmentExpression: (expr) ->
    @instrument expr, 'left', 'right'

  # Array expression: `[1, 2, 'red', true]`
  instrumentArrayExpression: (arr) ->
    @instrument arr, 'elements'

  # Binary expression: `3 + 4`
  instrumentBinaryExpression: (expr) ->
    @instrument expr, 'left', 'right'

  # Call expression: `foo()`
  instrumentCallExpression: (expr) ->
    @instrument expr, 'callee', 'arguments'

  # Ternary operator; `value ? 'ifTruthy' : 'ifFalsy'`.
  # Eventually, we'll want to replace the consequent and alternate with
  # anonymous self-evaluating functions so we can calculate branch coverage.
  instrumentConditionalExpression: (expr) ->
    @instrument expr, 'test', 'consequent', 'alternate'

  # Wraps an expression into a statement
  instrumentExpressionStatement: (expr) ->
    @instrument expr, 'expression'

  # Identifier: variable and function names. Do nothing.
  instrumentIdentifier: (ident) -> ident

  # Literal. Do nothing.
  instrumentLiteral: (lit) -> lit

  # Logical operators: `a || b`
  # Eventually, we'll want to replace the left and right sides with
  # anonymous self-evaluating functions to calculate branch coverage.
  instrumentLogicalExpression: (expr) ->
    @instrument expr, 'left', 'right'

  # Dot accessor: `obj.prop` or key accessor: `obj[propName]`
  instrumentMemberExpression: (expr) ->
    @instrument expr, 'object', 'property'

  # New expression
  instrumentNewExpression: (expr) ->
    @instrument expr, 'callee'

  # Object literal
  instrumentObjectExpression: (expr) ->
    @instrument expr, 'properties'

  # Property on an object: represents a key-value pair
  instrumentProperty: (prop) ->
    @instrument prop, 'key', 'value'

  # Comma-separated expressions
  instrumentSequenceExpression: (seq) ->
    @instrument seq, 'expressions'

  # `this` keyword. Do nothing.
  instrumentThisExpression: (expr) -> expr

  # Unary expression: `~x`
  instrumentUnaryExpression: (expr) ->
    @instrument expr, 'argument'

  # Update expression: `x++`
  instrumentUpdateExpression: (expr) ->
    @instrument expr, 'argument'

  # Variable declaration: `var x = 7, y = 2;`
  instrumentVariableDeclaration: (decn) ->
    @instrument decn, 'declarations'

  # Variable declarator: `x = 7` within `var x = 7, y = 2;`
  instrumentVariableDeclarator: (dectr) ->
    @instrument dectr, 'init'
