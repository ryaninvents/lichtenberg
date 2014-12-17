;(function(){
  io = io.connect();

  // Grab hold of our dependencies here, since
  // the user's scripts might override them.
  var $ = window.$;
  var _ = window._;
  var Bacon = window.Bacon;

  var $results = $('#lichtenberg');
  var traceStream = new Bacon.Bus(),
    expectStream = new Bacon.Bus();

  // If the `#lichtenberg` div is missing, just slap it on the page.
  if($results.length===0){
    $('body').append('<div id="lichtenberg"></div>');
    $results = $('#lichtenberg');
  }

  var BUFFER_TIME = 500,
    BUFFER_COUNT = 50;

  traceStream.bufferWithTimeOrCount(BUFFER_TIME,BUFFER_COUNT).onValue(function(expr){
    expr = expr.map(function(expr){expr.id = __lichtenberg_id;return expr});
    io.emit('trace', expr);
  });

  expectStream.bufferWithTimeOrCount(BUFFER_TIME,BUFFER_COUNT).onValue(function(expr){
    expr = expr.map(function(expr){expr.id = __lichtenberg_id;return expr});
    io.emit('expect', expr);
  });

  // Define our API.
  window.__Lichtenberg = {

    // `trace` gets called when a line of code runs.
    trace: function(expr){
      traceStream.push(expr);
    },

    // `expect` gets called on file load, and tells Lichtenberg
    // which lines of code are expected to run.
    expect: function(expr){
      expectStream.push(expr);
    },

    // `done` must be called from the user's script once it's done with
    // all its testing. Lichtenberg then goes through and verifies which
    // lines have run and which ones haven't, and outputs its report.
    done: function(){
      $results.html('<h3><i class="fa fa-spinner fa-spin"></i> Fetching coverage information...</h3>')
      setTimeout(function(){
        io.emit('done', {id:__lichtenberg_id});
      }, BUFFER_TIME+20);
    }
  };

  // Contact the server on page load so we can cache results.
  io.emit('ready', {id:__lichtenberg_id});

  $results.html($('#lichtenberg-waiting').html());

  // How to handle results coming back from the server.
  io.on('results', function(results){
    console.log(results);
    var files = results.files;
    // Nothing special here; it just fills the `#lichtenberg` div with
    // the template (found in modifyHTML.coffee) populated with the
    // actual coverage results.
    var tpl = _.template($('#lichtenberg-results-tpl').html());
    files = _.mapValues(files, function(res, filename){
      res.filename = filename;
      return res;
    });
    $results.html(tpl({results:_.values(files)}));
    $results.find('tr[data-content="filename"]').each(function(){
      var $filename = $(this),
        fnm = $filename.attr('data-file'),
        fileResults = results.files[fnm],
        $codeRow = $('tr[data-content="code"][data-file="'+fnm+'"]'),
        $codeCell = $codeRow.find('td');
      $filename.click(function(){
        $codeRow.toggleClass('collapsed');
        $.get('/lichtenberg/original'+fnm)
        .then(function(code){
          var
            nest = {children:[],range:[0, code.length],loc:{start:{line:'begin'},end:{line:'end'}}};
          function rangeContains(outer, inner){
            return +outer.range[0] <= +inner.range[0] && +outer.range[1] >= +inner.range[1];
          }
          function add(range, list){
            list.sort(function(a, b) {
              if (a[0] < b[0]) {
                return 1;
              } else if (b[0] < a[0]) {
                return -1;
              } else if (a[1] < b[1]) {
                return 1;
              } else if (b[1] < a[1]) {
                return -1;
              } else {
                return 0;
              }
            });

            var matches = list.filter(function(item){
              return rangeContains(item, range);
            });
            if(!matches.length){
              return list.push(range);
            }
            matches[0].children = matches[0].children || [];
            add(range, matches[0].children);
          }
          function getCaption(r){
            var type, lines;
            if(!r.type){
              type = '¯\\_(ツ)_/¯';
            } else {
              type = r.type.replace(/([A-Z][a-z]+)(.*)/, function($0, $1, $2){
                return $1 + ' ' + $2.toLowerCase();
              });
            }
            if(r.loc.start.line !== r.loc.end.line){
              lines = ', lines '+r.loc.start.line + '-' + r.loc.end.line;
            } else {
              lines = ', line '+r.loc.start.line;
            }
            return type + lines;
          }
          function cleancode(code){
            return code.split('\n').map(function(s){return s.replace(/^\s+/g,'')}).join('\n');
          }
          function getcode(range,b){
            if(b){
              range = [range, b];
            }
            return code.substring(range[0],range[1]);
          }
          function getCleanCode(range){
            return cleancode(getcode.call(null,arguments));
          }
          function mkdiv(r) {
            var $d,
              passedState = (r.executed===undefined?'display':r.executed? 'passed':'failed');
            $d = $("<code class='coverage "+passedState+"' title='"+getCaption(r)+"'></code>");
            if(r.children && r.children.sort) {
                r.children.sort(function(a,b){
                return a.range[0]-b.range[0];
              });
            }
            _.forEach(r.children, function(child, i, list) {
              $d.append(mkdiv(child));
              if(i<list.length-1){
                $d.append('<pre>'+cleancode(code.slice(child.range[1],list[i+1].range[0]))+'</pre>')
              }
            });
            if(r.children && r.children.length && r.range){
              var $first = $('<pre>'),
                $last = $('<pre>');
              $first.text(getCleanCode(r.range[0], r.children[0].range[0]));
              $last.text(getCleanCode(r.children[r.children.length-1].range[1],r.range[1]));
              $d.prepend($first);
              $d.append($last);
            }else if(r.range){
              var $first = $('<pre>');
              $first.text(getCleanCode(r.range[0], r.range[1]));
              $d.append($first);
            }
            return $d;
          }
          _.forIn(fileResults.lines, function(line, key){
            var range = key.split(':');
            line.range = range;
            add(line, nest.children);
          });
          $codeCell.html('').append(mkdiv(nest));

        })
        .fail(function(){
          $codeCell.html('<i class="fa fa-exclamation-triangle"></i> File not found')
        });
      });
    });
  });
})();
