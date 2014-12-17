methodDefs = ['./control-flow', './expression', './function'].map require

esprima = require 'esprima'
escodegen = require 'escodegen'
_ = require 'lodash'

DEFAULT_OPTIONS =
  functionCoverage: yes
  statementCoverage: yes
  branchCoverage: no
  conditionCoverage: no

module.exports = (opt) ->

  # Finds and executes the appropriate function to instrument
  # each child node.
  generateInstrumentation = (astNode, props...) ->

    # If we've passed in properties to iterate over...
    if props? and props.length

      # ...then we go get each child node and instrument it by
      # calling getInstrumentation without any properties.
      _.flatten(props).filter (prop) => astNode[prop]?.type
        .forEach (prop) =>
          @instrument astNode[prop]

      return astNode

    # If we get here, then we haven't passed in `props`. Go find
    # the named function that will give us the properties to
    # instrument on.
    type = astNode.type
    f = @["instrument#{type}"]

    throw new Error("Unrecognized node type #{type}") unless f?

    f(astNode)

    astNode

  # Iterate an array and instrument each item.
  instrumentEach = (astNodes, props...) ->

    # The result is flattened so we can do things like return
    # an array of nodes from our instrumentXYZ function to
    # replace a statement with two statements (instrumentation +
    # original statement).
    _.flatten astNodes.map (n) => @instrument n

  # Skim the instrumentation from all child nodes and attach it as our instrumentation.
  collectInstrumentation = (astNode, props...) ->
    if _.isArray astNode
      astNode.instrumentation = _.flatten astNode.map (node) =>
        @collectInstrumentation node, props
      return astNode
    if props? and props.length
      # Dirty hack in case we called as `@collectInstrumentation(node, [prop, prop2])`
      props = _.flatten props

      astNode.instrumentation = _.flatten props
        .filter (key) -> astNode[key].instrumentation?
        .map (key) -> astNode[key].instrumentation

      astNode

  # Combine all our method definitions from our modules.
  instrumentor = _.assign.apply _, [{}].concat methodDefs.map (f) -> f(opt)

  # #@instrument
  #
  # Simply calls the appropriately named function to do two things:
  #
  # 1. Recurse down the tree and generate instrumentation for child nodes.
  # 2. Attach the instrumentation to the node and return it.
  instrumentor.instrument = (astNode, props...) ->
    if astNode.length
      instrumentEach.apply @, arguments
    else
      generateInstrumentation.apply @, arguments
    collectInstrumentation.apply @, arguments

  # Create a call to `__Lichtenberg.trace()` or another `__Lichtenberg` method.
  instrumentor.lichtCall = (node, opt={}) ->

    lichFunc = opt?.func or 'trace'
    properties = opt.properties or
      loc: node.loc
      range: node.range
      type: node.type
      filename: node.filename

    # If we've provided a `name` function...
    if _.isFunction opt.name

      # ...use that function to get the name of our node.
      # Useful to instrument named functions.
      properties.name = opt.name(node)

    # Allow attachment of custom properties.
    # Circular references are not allowed here.
    if opt.attach?
      attachments = opt.attach

      # `attach` can be either a function or a constant.
      unless _.isFunction attach
        attachments = _.constant attachments

      _.assign properties, attachments(node)

    properties.toString = -> JSON.stringify properties
    {
      type: 'ExpressionStatement'
      expression:
        type: 'CallExpression'
        callee:
          type: 'MemberExpression'
          computed: no
          'object':
            type: 'Identifier'
            name: '__Lichtenberg'
          'property':
            type: 'Identifier'
            name: lichFunc
        'arguments':[{type:'Literal',value:properties}]
      _props: properties
    }

  # Make a block statement out of an expression.
  instrumentor.toBlock = (expr) ->
    if expr.type is 'BlockStatement'
      expr
    else if expr.type.match /Expression$|.*Function.*/
      @toBlock
        type: 'ExpressionStatement'
        expression: expr
    else
      type: 'BlockStatement'
      body: [expr]

  instrumentor.instrumentTree = (code, opt=DEFAULT_OPTIONS) ->
    opt = _.clone opt
    opt.loc = opt.range = yes
    _.defaults opt, DEFAULT_OPTIONS

    try
      ast = esprima.parse code, opt
      ast = @instrument ast
      escodegen.generate ast
    catch e
      throw e

  instrumentor
