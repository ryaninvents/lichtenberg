methodDefs = ['./control-flow', './expression', './function'].map require

children = require './children'

esprima = require 'esprima'
escodegen = require 'escodegen'
_ = require 'lodash'
path = require 'path'

childFunc = _.mapValues children, (childProps) ->
  # If this type can have child nodes (i.e. `childProps.length !== 0`),
  # create a function that will recurse down into them.
  if childProps.length
    (node) -> @instrument node, childProps
  # Otherwise, just pass the node through untouched. This happens with
  # Literals and Identifiers.
  else
    (node) -> node

DEFAULT_OPTIONS =
  functionCoverage: yes
  statementCoverage: yes
  branchCoverage: no
  conditionCoverage: no

# Generate a string with the given number of spaces so
# we can indent the debug output.
spaces = (n) -> [1...n].map(-> ' ').join('')

module.exports = (opt={}, code) ->
# Clean up the options object and add defaults.
  opt = _.clone opt
  opt.loc = opt.range = yes
  opt.indent = 0
  _.defaults opt, DEFAULT_OPTIONS

  # Finds and executes the appropriate function to instrument
  # each child node.
  generateInstrumentation = (astNode, props...) ->

    # If we've passed in properties to iterate over...
    if props? and props.length

      # ...then we go get each child node and instrument it by
      # calling `instrument` without any properties.
      opt.indent++

# Flatten so we can either call this function with `(node, prop, prop)`
# or `(node, [prop, prop])`.
      _.flatten(props).forEach (prop) =>
        astNode[prop] = instrumentor.instrument astNode[prop]

# If any of our instrumentation functions has returned an array, we want
# to make sure that array gets flattened out. This enables us to, for
# instance, return `[instrumentation, originalStatement]` in place of a
# given statement `originalStatement`.
        if _.isArray astNode[prop]
          astNode[prop] = _.flatten astNode[prop]

      opt.indent--

      return astNode

    # If we get here, then we haven't passed in `props`. Go find
    # the named function that will give us the properties to
    # instrument on.
    type = astNode.type
    f = instrumentor["instrument#{type}"]

    unless f?
      throw new Error("Unrecognized node type #{type}")

    newNode = f.call(instrumentor, astNode)
    newNode

  # Iterate an array and instrument each item.
  instrumentEach = (astNodes, props...) ->
    #console.log "iEach (#{astNodes[0...3].map((n) -> n.type).join(',')}#{if astNodes.length > 3 then " ...+#{astNodes.length-3} more" else ''})"
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
    originalFunc = instrumentor[funcName]

    # If we've defined special behavior...
    if originalFunc?
      # ...call our automatically-defined function beforehand.
      instrumentor[funcName] = (node) ->
        childFunc[nodeType].apply @, arguments
        originalFunc.apply(@, arguments) ? node
    else
      instrumentor[funcName] = childFunc[nodeType]

  # #instrument

  # Simply calls the appropriately named function to do two things:
  #
  # 1. Recurse down the tree and generate instrumentation for child nodes.
  # 2. Attach the instrumentation to the node and return it.
  instrumentor.instrument = (astNode, props...) ->
    return unless astNode?
    astNode.instrumentation ?= []
    if _.isArray astNode
      astNode = instrumentEach.apply instrumentor, arguments
    else
      astNode = generateInstrumentation.apply instrumentor, arguments
    instrumentor.collectInstrumentation.apply instrumentor, [astNode].concat props
    astNode


  # Skim the instrumentation from all child nodes and attach it to the given
  # AST node to keep track of it.
  instrumentor.collectInstrumentation = (astNode, props...) ->
    if _.isArray astNode
      astNode.instrumentation = _.flatten astNode.map (node) =>
        instrumentor.collectInstrumentation.call instrumentor, node, _.flatten props
        node.instrumentation
      return astNode

    unless props?.length
      props = children[astNode.type]

    # Dirty hack in case we called as `collectInstrumentation(node, [prop, prop2])`
    props = _.flatten props

    astNode.instrumentation = (astNode.instrumentation ? []).concat _.flatten(props.filter (key) ->
        _.isArray(astNode[key]) or astNode[key]?.instrumentation?.length
      .map (key) ->
        if _.isArray astNode[key]
          instrumentor.collectInstrumentation astNode[key]
        else
          astNode[key].instrumentation
    )

    astNode

  # #lichtCall

  # Create a call to `__Lichtenberg.trace()` or another `__Lichtenberg` method.
  instrumentor.lichtCall = (node, op={}) ->

    # Allow for passing in of another function name, but by
    # default call `trace()`.
    lichFunc = op?.func or 'trace'

    # Properties to add into the function call. You can overwrite them
    # but I don't think there's a reason to. I'll probably remove this
    # overwrite ability later on, so don't depend on it.
    properties = op.properties or
      loc: node.loc
      range: node.range
      type: node.type
      filename: node.filename or op.filename or opt.filename

    # If we've provided a `name` function...
    if _.isFunction op.name

      # ...use that function to get the name of our node.
      # Useful to instrument named functions.
      properties.name = op.name(node)

    # Allow attachment of custom properties.
    # Circular references are not allowed here.
    if op.attach?
      attachments = op.attach

      # `attach` can be either a function or a constant.
      unless _.isFunction attach
        attachments = _.constant attachments

      _.assign properties, attachments(node)

    properties.toString = -> JSON.stringify properties

    # Generate a tree that `escodegen` can use.
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

  # #toBlock

  # Make a block statement out of a statement.
  instrumentor.toBlock = (expr) ->
    if expr.type is 'BlockStatement'
      expr
    else if expr.type?.match /Statement$|Expression$|Literal|Identifier/
      # don't modify
      expr
    else if expr.type?.match /Function/
      @toBlock
        type: 'ExpressionStatement'
        expression: expr
        instrumentation: expr.instrumentation
    else
      type: 'BlockStatement'
      body: _.flatten [expr]
      instrumentation: expr.instrumentation

  # #instrumentCode

  # Generate an instrumented version of the given code.
  instrumentor.instrumentCode = (code) ->
    ast = esprima.parse code, opt
    ast = instrumentor.instrument ast
    try
      m = opt.fnShort.match /^(.*)\/([^/]+)$/
      fnm = opt.fnShort
      fPath = '/lichtenberg/original'
      if m.length > 1
        fnm = m[2]
        fPath = path.join '/lichtenberg/original', m[1]
# Source maps aren't working yet and I'm not sure why.
      escodegen.generate ast, sourceMap: path.join(fPath,fnm), sourceRoot: fPath, sourceMapWithCode: yes, sourceContent: code
    catch e
      throw e

# If we've passed in code with our opts, instrument the code.
  if code?
    instrumentor.instrumentCode code
# Otherwise, return a function we can reuse over and over.
  else
    instrumentor
