methodDefs = ['./control-flow', './expression', './function'].map require

children = require './children'

esprima = require 'esprima'
escodegen = require 'escodegen'
_ = require 'lodash'

DEFAULT_OPTIONS =
  functionCoverage: yes
  statementCoverage: yes
  branchCoverage: no
  conditionCoverage: no

spaces = (n) -> [1...n].map(-> ' ').join('')

module.exports = (opt={}, code) ->
  opt = _.clone opt
  opt.loc = opt.range = yes
  opt.indent = 0
  opt.debug = yes
  _.defaults opt, DEFAULT_OPTIONS

  # Finds and executes the appropriate function to instrument
  # each child node.
  generateInstrumentation = (astNode, props...) ->
    if opt.debug and not props?
      console.log "#{spaces opt.indent}-#{astNode.type}"

    # If we've passed in properties to iterate over...
    if props? and props.length

      # ...then we go get each child node and instrument it by
      # calling `instrument` without any properties.
      opt.indent++
      _.flatten(props).forEach (prop) =>
        instrumentor.instrument astNode[prop]
      opt.indent--

      return astNode

    # If we get here, then we haven't passed in `props`. Go find
    # the named function that will give us the properties to
    # instrument on.
    type = astNode.type
    f = instrumentor["instrument#{type}"]

    unless f?
      #console.log JSON.stringify astNode, null, 2
      throw new Error("Unrecognized node type #{type}")
    f.call(instrumentor, astNode)

  # Iterate an array and instrument each item.
  instrumentEach = (astNodes, props...) ->
    #console.log "iEach (#{astNodes[0..3].map((n) -> n.type).join(',')}...)"
    opt.indent++
    # The result is flattened so we can do things like return
    # an array of nodes from our instrumentXYZ function to
    # replace a statement with two statements (instrumentation +
    # original statement).
    i = _.flatten astNodes.map (n) => instrumentor.instrument n
    opt.indent--
    i

  # Combine all our method definitions from our modules.
  instrumentor = _.assign.apply _, [{}].concat methodDefs.map (f) -> f(opt)

  # Create a default implementation of `instrumentXYZ()`. If we don't specify
  # any special behavior for our instrumentation function, then check which child node types
  # our current node may have and recurse down into them.
  _.forOwn children, (childProps, nodeType) ->
    funcName = "instrument#{nodeType}"

    # If we've already defined special behavior, don't overwrite.
    return if instrumentor[funcName]

    # If this type can have child nodes (i.e. `childProps.length !== 0`),
    # create a function that will recurse down into them.
    instrumentor[funcName] = if childProps.length
      (node) ->
        @instrument node, childProps
    # Otherwise, just pass the node through untouched. This happens with
    # Literals and Identifiers.
    else
      (node) -> node

  # #@instrument
  #
  # Simply calls the appropriately named function to do two things:
  #
  # 1. Recurse down the tree and generate instrumentation for child nodes.
  # 2. Attach the instrumentation to the node and return it.
  instrumentor.instrument = (astNode, props...) ->
    return unless astNode
    astNode.instrumentation ?= []
    if _.isArray astNode
      instrumentEach.apply instrumentor, arguments
    else
      generateInstrumentation.apply instrumentor, arguments
    instrumentor.collectInstrumentation.apply instrumentor, [astNode].concat props
    astNode


  # Skim the instrumentation from all child nodes and attach it to the given
  # AST node to keep track of it.
  instrumentor.collectInstrumentation = (astNode, props...) ->
    if _.isArray astNode
      astNode.instrumentation = _.flatten astNode.map (node) =>
        instrumentor.collectInstrumentation.call instrumentor, node, _.flatten props
      return astNode
    if props? and props.length
      # Dirty hack in case we called as `collectInstrumentation(node, [prop, prop2])`
      props = _.flatten props

      astNode.instrumentation = astNode.instrumentation.concat _.flatten(props.filter (key) ->
          astNode[key]?.instrumentation?.length
        .map (key) -> astNode[key].instrumentation
      )

    astNode

  # Create a call to `__Lichtenberg.trace()` or another `__Lichtenberg` method.
  instrumentor.lichtCall = (node, opt={}) ->

    # Allow for passing in of another function name, but by
    # default call `trace()`.
    lichFunc = opt?.func or 'trace'

    # Properties to add into the function call. You can overwrite them
    # but I don't think there's a reason to. I'll probably remove this
    # overwrite ability later on, so don't depend on it.
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

  instrumentor.instrumentTree = (code) ->
    ast = esprima.parse code, opt
    ast = instrumentor.instrument ast
    escodegen.generate ast

  if code?
    instrumentor.instrumentTree code
  else
    instrumentor
