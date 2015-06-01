const koa = require('koa');
const config = require('./config');
const path = require('path');

if (!config) {
  console.error('No `lichtenberg.json` found in current directory; exiting.');
  process.exit(-1);
}

const serveStaticFiles = require('./staticFiles');
const serveLichtenbergFiles = serveStaticFiles.lichtenbergFiles;
const instrumentFiles = require('./instrumentFiles');

module.exports = function(){
  const app = koa();

  serveLichtenbergFiles(app);
  adjustFilepaths(app);
  instrumentFiles(app);
  serveStaticFiles(app);

  return app;
}


// Redirect root path to the test page, and remove the prefix from
// the rest of the files so the static server can find them.
function adjustFilepaths(app) {
  app.use(function *(next) {
    if (this.request.path === '/') {
      this.response.redirect(path.join(config.serveAs, config.entry));
    } else if (this.request.path.indexOf(config.serveAs) === 0) {
      this.request.path = this.request.path.replace(config.serveAs, '');
      yield next;
    }
  });
}
