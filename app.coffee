app = require('express.io')()
esprima = require 'esprima'
fs = require 'fs'

app.http().io()

instrument = require './lib/instrument'

app.io.route 'ready', (req) ->
  req.io.emit 'talk', message: "hello client"

app.io.route 'instrument', (req) ->
  code = req.data.code
  req.io.emit 'instrument', code: instrument(code, req.data)

app.get '/', (req, res) ->
  res.sendfile __dirname+'/public/index.html'

app.get /\/.*/, (req, res) ->
  fnm = "#{__dirname}/public#{req.path}"
  if fs.existsSync(fnm)
    res.sendfile fnm
  else
    fnm = __dirname + req.path.replace /^\/vendor/, "/bower_components"
    if fs.existsSync fnm
      res.sendfile fnm
    else
      res.status(404).send "nope, no #{fnm}"

app.listen(9796)
console.log "Listening on port 9796"
