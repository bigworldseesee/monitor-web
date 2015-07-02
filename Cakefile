{spawn, exec} = require 'child_process'
fs = require 'fs'

ENV = '/usr/bin/env'
COFFEE = "#{ ENV } coffee"

task 'build', "Builds bwcc_monitor package", ->
  invoke 'compile'

task 'compile', "Compiles CoffeeScript src/*.coffee to *.js", ->
  console.log "Compiling src/*.coffee to *.js"
  exec "#{COFFEE} --compile --output #{__dirname} #{__dirname}/src/", (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr if stdout + stderr
    fs.renameSync('index.js', 'routes/index.js')
    fs.renameSync('user.js', 'routes/user.js')
    fs.renameSync('recent.js', 'routes/recent.js')
    fs.renameSync('db.js', 'model/db.js')
    fs.renameSync('config.js', 'model/config.js')
  
