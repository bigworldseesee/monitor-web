# util.coffee
fs = require 'fs'
events = require 'events'


class TimeStamp
  constructor: (@year, @month, @day, @time) ->
  toDate: -> new Date([@year, @month, @day, @time].join(' '))


class FileWatcher extends events.EventEmitter
  constructor: (@filePath, @close_on_change=true)->
  watch: ->   
    watcher = fs.watch @filePath, (event, filename) =>
      if event is 'change'
        watcher.close()
        @emit 'change'


module.exports.TimeStamp = TimeStamp
module.exports.FileWatcher = FileWatcher