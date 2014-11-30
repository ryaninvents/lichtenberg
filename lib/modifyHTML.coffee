path = require 'path'
fs = require 'fs'
cheerio = require 'cheerio'
uuid = require('node-uuid')

module.exports =
addLichtenberg = (htmlFile, opt) ->
  {callback} = opt
  htmlFile = path.join (opt.cwd ? process.cwd()), htmlFile
  fs.readFile htmlFile, (err, source) ->
    if err then return callback err
    $ = cheerio.load source
    $('body').prepend('<script src="/lichtenberg/lichtenberg.js"></script>');
    $('body').prepend("<script>var __lichtenberg_id = '#{uuid.v4()}';</script>")
    $('body').prepend('<script src="/socket.io/socket.io.js"></script>');
    callback null, $('html').html()
