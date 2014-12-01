esprima = require 'esprima'
escodegen = require 'escodegen'
_ = require 'lodash'

DEFAULT_OPTIONS =
  functionCoverage: yes
  statementCoverage: yes

getInstrumentation = (func, opt = {}) ->
  lichFunc = opt?.func or "trace"
  properties = opt.properties or
    loc: func.loc
    range: func.range
    name:
      if opt.name isnt no
        func.id?.name or '«anonymous function»'
      else
        undefined
    type: func.type
    filename: opt.filename
    #shortname: "#{opt.filename}:#{func.range[0]}:#{func.range[1]}"

  properties.placement = opt?.placement

  properties.toString = -> JSON.stringify properties
  {
    type: "ExpressionStatement"
    expression: {
        type: "CallExpression"
        callee: {
            type: "MemberExpression"
            computed: no
            "object": {
                type: "Identifier"
                name: "__Lichtenberg"
            }
            "property": {
                type: "Identifier",
                name: lichFunc
            }
        }
        "arguments": [
            {
                type: "Literal",
                value: properties
            }
        ]
    }
    _props: properties
  }

# Instrument an ExpressionStatement.
instrumentStatement = (ast, opt={}) ->
  instrumentTree(ast.expression, opt)
  after = no#ast.type isnt "ReturnStatement"
  instrumentation1 = getInstrumentation(ast, _.defaults(_.clone(opt),{name:no,placement:'before'}))
  if after
    instrumentation2 = getInstrumentation(ast, _.defaults(_.clone(opt),{name:no,placement:'after'}))
  if after
    ast.instrumentation = [instrumentation1, instrumentation2]
    out = [instrumentation1, ast, instrumentation2]
    out.instrumentation = ast.instrumentation
    out
  else
    ast.instrumentation = [instrumentation1]
    out = [instrumentation1, ast]
    out.instrumentation = ast.instrumentation
    out

instrumentTree = (ast, opt=DEFAULT_OPTIONS) ->
  return ast unless ast
  ins = (item) -> instrumentTree item, opt
  imap = (arr) -> _.flatten arr.map(ins), true
  switch ast.type
    when 'AssignmentExpression'
      instrumentTree ast.right, opt
      ast.instrumentation = ast.right.instrumentation
    when 'ArrayExpression'
      ast.elements = imap ast.elements
      ast.instrumentation = _.flatten ast.elements.map (el) -> el.instrumentation
    when 'BlockStatement'
      ast.body = imap ast.body
      ast.instrumentation = _.flatten ast.body.map (el) -> el.instrumentation
    when 'BinaryExpression'
      ins ast.left
      ins ast.right
      ast.instrumentation = ast.left.instrumentation.concat(ast.right.instrumentation)
    when 'BreakStatement'
      ast.instrumentation = []
    when 'CallExpression'
      ins ast.callee
      ast['arguments'] = imap ast['arguments']
      ast.instrumentation = ast.callee.instrumentation.concat _.flatten ast['arguments'].map (el) -> el.instrumentation
      console.log 'CallExpression', ast.instrumentation.filter _.identity
    when 'CatchClause'
      ins ast.body
      ast.instrumentation = ast.body.instrumentation
    when 'ConditionalExpression' # ternary x?y:z
      # TODO branch and condition coverage
      ins ast.test
      ins ast.consequent
      ins ast.alternate
      ast.instrumentation = _.flatten ['test','consequent','alternate'].map (name) -> ast[name].instrumentation
    when 'ContinueStatement'
      ast.instrumentation = []
    when 'DoWhileStatement'
      ins ast.body
      ins ast.test
      ast.instrumentation = ast.body.instrumentation.concat ast.test.instrumentation
    when 'DebuggerStatement'
      ast.instrumentation = []
    when 'EmptyStatement'
      ast.instrumentation = []
    when 'ExpressionStatement'
      if opt.statementCoverage or true
        ast = instrumentStatement(ast, opt)
        # instrumentation has already been attached after the above call
      else
        instrumentTree ast.expression, opt
        ast.instrumentation = ast.expression.instrumentation
    when 'ForStatement'
      ins ast.init
      ins ast.test
      ins ast.update
      ins ast.body
      ast.instrumentation = _.flatten ['init','test','update','body'].filter((name) -> ast[name]).map (name) ->
        ast[name].instrumentation
    when 'ForInStatement'
      ins ast.left
      ins ast.right
      ins ast.body
      ast.instrumentation = _.flatten ['left','right','body'].map (name) -> ast[name].instrumentation
    when 'FunctionDeclaration', 'FunctionExpression'
      ins ast.body
      #ast.body.body = imap ast.body.body
      inst = getInstrumentation ast, opt
      #ast.body.body.unshift inst
      ast.instrumentation = [inst].concat ast.body.instrumentation
    when 'Identifier'
      ast.instrumentation = []
    when 'IfStatement'
      # TODO: branch and condition coverage
      instrumentTree ast.consequent, opt
      ast.instrumentation = ast.consequent.instrumentation
      if ast.alternate
        instrumentTree ast.alternate, opt
        ast.instrumentation = ast.instrumentation.concat ast.alternate
    when 'Literal'
      ast.instrumentation = []
    when 'LabeledStatement'
      instrumentTree ast.body, opt
      ast.instrumentation = ast.body.instrumentation
    when 'LogicalExpression'
      ins ast.left
      ins ast.right
      ast.instrumentation = ast.left.instrumentation.concat ast.right.instrumentation
    when 'MemberExpression'
      ins ast.property
      ins ast.object
      ast.instrumentation = ast.property.instrumentation.concat ast.object.instrumentation
    when 'NewExpression'
      ins ast.callee
      ast.instrumentation = ast.callee.instrumentation
    when 'ObjectExpression'
      ast.properties = imap ast.properties
      ast.instrumentation = _.flatten ast.properties.map (prop) -> prop.instrumentation
    when 'Program'
      imap ast.body
      ast.body.filter((line)->line and line.expression).forEach (line) -> line.instrumentation = line.expression.instrumentation
      #console.log 'prog ast.body', JSON.stringify ast.body,null,2
      console.log 'prg body[1].expression', ast.body[1].expression
      ast.instrumentation = _.flatten ast.body.filter((line)->line.instrumentation).map (line) -> line.instrumentation
      console.log 'Program', ast
    when 'Property'
      ast.value = ins ast.value
      ast.instrumentation = ast.value.instrumentation
    when 'ReturnStatement'
      if opt.statementCoverage
        ast = instrumentStatement(ast, opt)
      else
        instrumentTree ast.argument, opt
        ast.instrumentation = ast.argument.instrumentation
    when 'SequenceExpression'
      ast.expressions = imap ast.expressions
      ast.instrumentation = _.flatten ast.expressions.map (ex) -> ex.instrumentation
    when 'SwitchStatement'
      ins ast.discriminant
      ast.cases = imap ast.cases
      ast.instrumentation = _.flatten ast.cases.map (ca) -> ca.instrumentation
    when 'SwitchCase'
      ins ast.consequent
      ast.instrumentation = _.clone ast.consequent.instrumentation
      if ast.test
        ins ast.test
        ast.instrumentation = _.flatten ast.instrumentation, ast.test.instrumentation
    when 'ThisExpression'
      ast.instrumentation = []
    when 'TryStatement'
      ins ast.body
      ast.instrumentation = ast.body.instrumentation
    when 'UnaryExpression', 'UpdateExpression', 'ThrowStatement'
      ins ast.argument
      ast.instrumentation = ast.argument.instrumentation
    when 'VariableDeclaration'
      ast.declarations = imap ast.declarations
      ast.instrumentation = _.flatten ast.declarations.map (dec) -> dec.instrumentation
    when 'VariableDeclarator'
      if ast.init
        ins ast.init
        ast.instrumentation = ast.init.instrumentation
      else
        ast.instrumentation = []
    when 'WhileStatement'
      ins ast.test
      ins ast.body
      ast.instrumentation = ast.test.instrumentation.concat ast.body.instrumentation
    when 'WithStatement'
      ins ast.object
      ins ast.body
      ast.instrumentation = ast.object.instrumentation.concat ast.body.instrumentation
  ast

createExpectStatements = (ast) ->
  inst = ast.instrumentation.filter(_.identity).map((x)->x._props).filter(_.identity)
  inst.map (ins) ->
    getInstrumentation null,
      properties: ins
      func: "expect"

instrument = (code, opt=DEFAULT_OPTIONS) ->
  _.extend opt,
    loc: yes
    range: yes
  _.defaults opt, DEFAULT_OPTIONS
  ast = esprima.parse code, opt
  ast = instrumentTree ast, opt
  try
    expects = createExpectStatements(ast)
    ast.body = expects.concat ast.body
    escodegen.generate ast
  catch e
    ast.error = e.toString()
    console.error(e)
    JSON.stringify ast, null, 2
    throw e

module.exports = instrument
