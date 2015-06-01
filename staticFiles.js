const static = require('koa-static');
const config = require('./config');
const path = require('path');

function staticFiles(app){
  app.use(static(config.dir, {
    hidden: config.serveHiddenFiles
  }));
}

// TODO: add a Gulp script to generate lichtenberg.js and lichtenberg.css
// from source (ES6/Less)
staticFiles.lichtenbergFiles = function lichtenbergFiles(app) {
  app.use(static(path.join(__dirname, 'public')));
};

module.exports = staticFiles;
