module.exports = (opt) ->

  # Assignment expression: `x = 7`.
  instrumentAssignmentExpression: (expr) ->
    @instrument expr, 'left', 'right'

  # Ternary operator; `value ? 'ifTruthy' : 'ifFalsy'`.
  # Eventually, we'll want to replace the consequent and alternate with
  # anonymous self-evaluating functions so we can calculate branch coverage.
  instrumentConditionalExpression: (expr) ->
    @instrument expr, 'test', 'consequent', 'alternate'

  # Logical operators: `a || b`
  # Eventually, we'll want to replace the left and right sides with
  # anonymous self-evaluating functions to calculate branch coverage.
  instrumentLogicalExpression: (expr) ->
    @instrument expr, 'left', 'right'

  # Dot accessor: `obj.prop` or key accessor: `obj[propName]`
  instrumentMemberExpression: (expr) ->
    @instrument expr, 'object', 'property'

  # Update expression: `x++`
  instrumentUpdateExpression: (expr) ->
    @instrument expr, 'argument'

  # Variable declaration: `var x = 7, y = 2;`
  instrumentVariableDeclaration: (decn) ->
    @instrument decn, 'declarations'

  # Variable declarator: `x = 7` within `var x = 7, y = 2;`
  instrumentVariableDeclarator: (dectr) ->
    @instrument dectr, 'init'
