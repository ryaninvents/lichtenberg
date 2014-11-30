;(function(){
  io = io.connect();

  // Grab hold of our dependencies here, since
  // the user's scripts might override them.
  var $ = window.$;
  var _ = window._;
  var Bacon = window.Bacon;

  // Define our API.
  window.__Lichtenberg = {

    // `trace` gets called when a line of code runs.
    trace: function(expr){
      expr.id = __lichtenberg_id;
      io.emit('trace', expr);
    },

    // `expect` gets called on file load, and tells Lichtenberg
    // which lines of code are expected to run.
    expect: function(expr){
      expr.id = __lichtenberg_id;
      io.emit('expect', expr);
    },

    // `done` must be called from the user's script once it's done with
    // all its testing. Lichtenberg then goes through and verifies which
    // lines have run and which ones haven't, and outputs its report.
    done: function(){
      io.emit('done', {id:__lichtenberg_id});
    }
  };

  // Contact the server on page load so we can cache results.
  io.emit('ready', {id:__lichtenberg_id});

  // How to handle results coming back from the server.
  io.on('results', function(results){

    // Nothing special here; it just fills the `#lichtenberg` div with
    // the template (found in modifyHTML.coffee) populated with the
    // actual coverage results.
    var $results = $('#lichtenberg');
    var tpl = _.template($('#lichtenberg-results-tpl').html());
    results = _.mapValues(results, function(res, filename){
      res.filename = filename;
      return res;
    });
    // If the `#lichtenberg` div is missing, just slap it on the page.
    if($results.length===0){
      $('body').append('<div id="lichtenberg"></div>');
      $results = $('#lichtenberg');
    }
    $results.html(tpl({results:_.values(results)}));
  });
})();
