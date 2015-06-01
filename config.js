'use strict';

const path = require('path');
const fs = require('fs');
const _ = require('lodash');
const Minimatch = require('minimatch').Minimatch;

const PWD = process.env.PWD;
const confPath = path.join(PWD, 'lichtenberg');

const config = (function(){
  if (fs.existsSync(confPath + '.json')) {
    return require(confPath);
  } else {
    return null;
  }
})();

if (config) {

  // `config.entry`: The URL of your test page. Defaults to `"index.html"`.
  if (!config.entry) {
    config.entry = 'index.html';
  }

  // `config.serveAs`: The URL path to serve the files under.
  // Useful when your app will ultimately deploy on a server with other
  // apps, or behind a reverse proxy.
  if (!config.serveAs) {
    config.serveAs = '/';
  }

  // `config.exclude`: An array of globs to exclude from instrumentation.
  // By default, Lichtenberg will instrument any code that gets served.
  if (_.isArray(config.exclude)) {
    let exclude = config.exclude.map(function(glob){ return new Minimatch(glob).makeRe();} );
    config.exclude = function (filename) {
      return _.any(exclude, function (re) {
        return re.test(filename);
      });
    }
  } else {
    config.exclude = _.constant(false);
  }

  // `config.dir`: A path to the project's static files, relative to
  // where `lichtenberg.json` is found. If unspecified, just serve the current directory.
  if (config.dir) {
    config.dir = path.join(PWD, config.dir);
  } else {
    config.dir = PWD;
  }

  // `config.indexFile`: When the browser requests a path that ends in a directory (e.g.
  // `/tests/`), serve this file from that directory. Defaults to `"index.html"`. You
  // probably don't need to touch this.

  // `config.serveHiddenFiles`: A boolean that determines whether hidden files are
  // served or not. Probably doesn't matter. Defaults to false.
  config.serveHiddenFiles = Boolean(config.serveHiddenFiles);

  // `config.include`: Glob to use to determine which files to instrument.
  // Defaults to *.js files, but you can override it if, for instance, you want to
  // save your files as *.es6 or something. The path is tested as served.
  if (!config.include) {
    config.include = "**/*.js";
  }
  config.include = new Minimatch(config.include).makeRe();

}

module.exports = config;
