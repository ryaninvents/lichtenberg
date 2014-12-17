# Lichtenberg

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/baconscript/lichtenberg?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Lichtenberg figure, made by high-voltage electrical discharge through a block of acrylic](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/PlanePair2.jpg/264px-PlanePair2.jpg)](https://en.wikipedia.org/wiki/Lichtenberg_figure)

A JavaScript code coverage and debugging library. Still in alpha.

[![NPM version](https://img.shields.io/npm/v/lichtenberg.svg?style=flat)](https://www.npmjs.org/package/lichtenberg)
[![NPM downloads](https://img.shields.io/npm/dm/lichtenberg.svg?style=flat)](https://www.npmjs.org/package/lichtenberg)
[![License](https://img.shields.io/npm/l/lichtenberg.svg?style=flat)](LICENSE.md)

## What is it?
Lichtenberg reads your code and annotates it with trace statements. Then, when you view your tests in a browser, it watches for those trace statements and keeps track of how many were run. From this, it creates a coverage report telling you how much of your code was actually run during the test. Strive for 100%!

Lichtenberg aims to be as independent as possible of whatever testing framework you choose. It's been proven to work with Mocha, but should also work with QUnit, Jasmine, etc.

## Installing

    $ npm install -g lichtenberg

## Trying it out
You can try Lichtenberg with the sample `test` folder included in this repository. Requires [Grunt](http://gruntjs.com/).

```
$ git clone https://github.com/baconscript/lichtenberg.git
$ cd lichtenberg
$ npm install && grunt
$ cd test
$ lichtenberg
```

Try adding more tests in `test.html` and watching the coverage go up! The library being tested is [format](https://github.com/samsonjs/format).

## Setup

To run Lichtenberg coverage on your project, first create a `lichtenberg.json` file in your project root.

```
{
  "entry": "test.html",
  "include": ["assets"],
  "exclude": ["bower_components"],
  "serveAs": "/apps/myApp"
}
```

* `entry`: HTML page that runs your tests. Lichtenberg will inject a couple of script tags and a div into it to generate the code coverage.
* `include`: Regular expression indicating which files to instrument for coverage.
* `exclude`: Regular expression indicating which files to ignore when instrumenting. Good candidates for this would be any external libraries you're using.
* `serveAs`: Path to your entry point on the server. This is helpful if you have absolute paths in your code and need to preserve them. For instance, if your test page is served at `/apps/myApp/test.html`, setting `serveAs` to be `/apps/myApp` will serve all the files in the project from that path.

### Add `__Lichtenberg.done()` to your code
In your test suite, add the following code in a place where it will run after all tests should have completed.

```
if(window.__Lichtenberg) {
  __Lichtenberg.done();
}
```

Or, if you want something shorter: `window.__Lichtenberg && __Lichtenberg.done()`

In Mocha's [BDD style](http://mochajs.org/#interfaces), this may be achieved by wrapping all your tests in a `describe()` and adding the code to an `after()` function.

When `done()` is called, Lichtenberg runs through all the lines of code that it is aware of, computes coverage on each file, and displays the results in your browser.

## Running
From the same directory as your `lichtenberg.json` file, just type `lichtenberg` to start the server. Visit <http://localhost:9796> in your browser to view the results. Report generation is [coming soon](https://github.com/baconscript/lichtenberg/issues/2).

![Sample tests using Mocha](sample-coverage.png)
