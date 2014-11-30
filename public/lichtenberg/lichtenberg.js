;(function(){
  io = io.connect();

  var $ = window.$;
  var _ = window._;

  window.__Lichtenberg = {
    trace: function(expr){
      expr.id = __lichtenberg_id;
      setTimeout(function(){io.emit('trace', expr);},Math.random()*1000);
    },
    expect: function(expr){
      expr.id = __lichtenberg_id;
      io.emit('expect', expr);
    },
    done: function(){
      io.emit('done', {id:__lichtenberg_id});
    }
  };

  io.emit('ready', {id:__lichtenberg_id});
  io.on('results', function(results){
    var $results = $('#lichtenberg');
    var tpl = _.template($('#lichtenberg-results-tpl').html());
    results = _.mapValues(results, function(res, filename){
      res.filename = filename;
      return res;
    });
    if($results.length===0){
      $('body').append('<div id="lichtenberg"></div>');
      $results = $('#lichtenberg');
    }
    $results.html(tpl({results:_.values(results)}));
  });
})();
