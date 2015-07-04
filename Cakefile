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
    fs.mkdirSync('routes/') if not fs.existsSync('routes/')
    fs.mkdirSync('model/') if not fs.existsSync('model/')
    fs.renameSync('index.js', 'routes/index.js')
    fs.renameSync('user.js', 'routes/user.js')
    fs.renameSync('db.js', 'model/db.js')
    fs.renameSync('usage_chart.js', 'public/javascripts/usage_chart.js')
  