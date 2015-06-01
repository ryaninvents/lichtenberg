'use strict';

const config = require('./config');
const fondue = require('fondue');
const genify = require('thunkify-wrap').genify;
const streamToBuffer = genify(require('stream-to-buffer'));
const isstream = require('isstream');
const cheerio = require('cheerio');

const JS_RE = config.include;
const EXCLUDE = config.exclude;

module.exports = function (app) {
  app.use(function *(next) {
    var contents;
    yield next;
    contents = this.response.body;

    function *getContents() {
      if (isstream(contents)) {
        contents = yield *streamToBuffer(contents);
      }
    }

    if (this.request.path === config.entry) {
      yield *getContents();
      let $ = cheerio.load(contents);
      $('head')
        .prepend('<script src="/socket.io/socket.io.js"></script>'
          + '<script src="/lichtenberg.js"></script>');
      this.response.body = $.html();
      return;
    }
    if (!JS_RE.test(this.request.path) || EXCLUDE(this.request.path)) {
      return;
    }

    yield *getContents();

    const instrumentation = fondue.instrument(contents.toString(), {
      path: this.request.path
    });

    contents = instrumentation.toString();

    this.response.body = [
      contents,
      '\n//@ sourceMappingURL=data:application/json;base64,',
      new Buffer(instrumentation.map.toString()).toString('base64')
    ].join('');
  });
};
