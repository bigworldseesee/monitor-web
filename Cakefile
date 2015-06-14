{spawn, exec} = require 'child_process'
fs = require 'fs'

ENV = '/usr/bin/env'
COFFEE = "#{ ENV } coffee"

task 'build', "Builds bwcc_monitor package", ->
  invoke 'compile'

task 'compile', "Compiles CoffeeScript src/*.coffee to lib/*.js", ->
  console.log "Compiling src/*.coffee to lib/*.js"
  exec "#{COFFEE} --compile --output #{__dirname}/lib/ #{__dirname}/src/", (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr if stdout + stderr
    fs.renameSync('lib/app.js', 'app.js')
    fs.renameSync('lib/index.js', 'routes/index.js')
  