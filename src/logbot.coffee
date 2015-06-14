# logbot.coffee
fs = require 'fs'

logPath = './res/mock.log'

generatLog =  (logPath, time) ->
  setTimeout ->
    # TODO: make logMessage like real PPTP log and the time should vary too.
    logMessage = new Date()
    fs.appendFile logPath, logMessage + '\n', (err) =>
      generatLog logPath, time
  , time


fs.closeSync fs.openSync(logPath, 'w')
generatLog logPath, 1000
