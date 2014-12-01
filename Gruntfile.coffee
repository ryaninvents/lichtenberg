sh = require 'shelljs'
path = require 'path'

module.exports = (grunt) ->
  grunt.initConfig()
  grunt.registerTask 'default', ['bower-install','copy-bower']
  grunt.registerTask 'refresh', ['clean', 'default']
  grunt.registerTask 'bower-install', ->
    sh.exec [path.join(__dirname, 'node_modules/.bin/bower'), 'install'].join ' '
  grunt.registerTask 'copy-bower', ['bower-install'], ->
    sh.cp path.join(__dirname, 'bower_components/datediff/datediff.js'), path.join(__dirname, 'test/assets/datediff.js')
    sh.cp '-r', path.join(__dirname, 'bower_components'), path.join(__dirname, 'test/assets/')
  grunt.registerTask 'clean', ->
    sh.rm '-rf', 'bower_components'
    sh.rm '-rf', 'test/assets/bower_components'
