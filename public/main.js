io = io.connect();

// Emit ready event.
io.emit('ready');

var editor = ace.edit("editor");
editor.getSession().setMode("ace/mode/javascript");

function instrumentCode(){
  var code = editor.getValue();
  io.emit('instrument', {
    code: code,
    filename: $('#filename').val()
  });
}

io.on('instrument',function(results){
  $('#results').text(results.code);
});

$('#instrument').click(instrumentCode);

editor.commands.addCommand({
  name: "Instrument",
  bindKey: "Ctrl-Enter",
  exec: instrumentCode
});

$('#filename').val('foo.js');
editor.setValue("function foo(x){\n    x = 7;\n    return x*3;\n}");
