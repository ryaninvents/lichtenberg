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
    $('body').prepend """
    <script type="text/x-template" id="lichtenberg-waiting">
    <h3>Running tests, please be patient...</h3>
    </script>
    <script type="text/x-template" id="lichtenberg-results-tpl">
    <h1>Code coverage</h1>
    <table>
      <% _.forEach(results, function(result){ 
      var amt = result.totalTraced/result.totalExpected,
          amtPct = Math.round(amt*100),
          barClass = amt < .60? "unacceptable" : amt < .80 ? "iffy" : "acceptable";
      %>
      <tr>
      <td><%- result.filename %></td>
      <td class="coverage">
        <div class="covbar <%- barClass %>" style="width:<%- amtPct %>%"></div>
        <span class="cov-text"><%- result.totalTraced %>/<%- result.totalExpected %>
      (<%- amtPct %>%)</span></td>
      </tr>
      <% }); %>
    </table>
    </script>
    <script src="/socket.io/socket.io.js"></script>
    <script>var __lichtenberg_id = '#{uuid.v4()}';</script>
    <script src="/lichtenberg/vendor/jquery/dist/jquery.js"></script>
    <script src="/lichtenberg/vendor/lodash/dist/lodash.js"></script>
    <script src="/lichtenberg/lichtenberg.js"></script>
    """
    $('head').prepend """
    <link rel="stylesheet" href="/lichtenberg/lichtenberg.css">
    """
    callback null, $('html').html()
