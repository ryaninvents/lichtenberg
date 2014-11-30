io = io.connect();

__Lichtenberg = {
  trace: function(expr){
    expr.id = __lichtenberg_id;
    setTimeout(function(){io.emit('trace', expr);},Math.random()*1000);
  },
  expect: function(expr){
    expr.id = __lichtenberg_id;
    io.emit('expect', expr);
  },
  verify: function(){
    console.log('verifying');
    io.emit('verify', {id:__lichtenberg_id});
  },
  done: function(){
    console.log('Licht done');
    io.emit('done', {id:__lichtenberg_id});
  }
};

io.emit('ready', {id:__lichtenberg_id});
io.on('results', console.log.bind(console,'RESULTS'));
