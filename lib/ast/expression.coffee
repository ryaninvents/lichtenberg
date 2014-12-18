module.exports = (opt) ->
  # Ternary operator; `value ? 'ifTruthy' : 'ifFalsy'`.
  # Eventually, we'll want to replace the consequent and alternate with
  # anonymous self-evaluating functions so we can calculate branch coverage.
  instrumentConditionalExpression: (expr) -> expr
