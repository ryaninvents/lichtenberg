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
    # TODO this is idiotic and has got to (mostly) go
    # the whole #lichtenberg-results-tpl ought to be loaded async'ly
    $('body').prepend """
    <script type="text/x-template" id="lichtenberg-waiting">
    <h3><i class="fa fa-spinner fa-spin"></i> Running tests, please be patient...</h3>
    </script>
    <script type="text/x-template" id="lichtenberg-results-tpl">
    <h1>Code coverage</h1>
    <table>
      <% _.forEach(results, function(result){
      var amt = result.totalTraced/result.totalExpected,
          amtPct = Math.round(amt*100),
          barClass = amt < .60? "unacceptable" : amt < .80 ? "iffy" : "acceptable";
      %>
      <tr data-file="<%- result.filename %>" data-content="filename">
      <td>
        <i class="fa fa-caret-right"></i>
        <%- result.filename %>
        <div style="display:none;" type="text/x-coverage-results">
        <%- JSON.stringify(result) %>
        </div>
      </td>
      <td class="coverage">
        <div class="covbar <%- barClass %>" style="width:<%- amtPct %>%"></div>
        <span class="cov-text"><%- result.totalTraced %>/<%- result.totalExpected %>
      (<%- amtPct %>%)</span></td>
      </tr>
      <tr data-file="<%- result.filename %>" data-content="code" class="collapsed">
        <td colspan=2>
        </td>
      </tr>
      <% }); %>
    </table>
    </script>
    <script src="/socket.io/socket.io.js"></script>
    <script>var __lichtenberg_id = '#{uuid.v4()}';</script>
    <script src="/lichtenberg/vendor/jquery/dist/jquery.js"></script>
    <script src="/lichtenberg/vendor/bacon/dist/Bacon.js"></script>
    <script src="/lichtenberg/vendor/lodash/dist/lodash.js"></script>
    <script src="/lichtenberg/lichtenberg.js"></script>
    """
    $('head').prepend """
    <link rel="stylesheet" href="/lichtenberg/lichtenberg.css">
    """
    callback null, $('html').html()
