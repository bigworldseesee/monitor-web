fs = require 'fs'
events = require 'events'
mongoose = require 'mongoose'
database = require './database'

# create the model for users and expose it to our app
userModel = database.userModel
logModel = database.logModel
sessionModel = database.sessionModel


class LogHarvester
  constructor: (@path) ->
    @activeSessions = {}

  run: ->
    logModel.findOne {'name': @path},  (err, log) =>
      if err
        console.log(err)
      if not log
        log = new logModel
        log.name = @path
        log.prevSize = 0
        log.save (err) =>
          if err
            console.log(err)
          @_log = log
          @harvest()
      else
        @_log = log
        @prevSize = 0 # @_log.prevSize
        @harvest()

  harvest: ->
    @currSize = fs.statSync(@path).size
    if @currSize > @prevSize
      rstream = fs.createReadStream @path,
        encoding: 'utf8'
        start: @prevSize
        end: @currSize
      @prevSize = @currSize
      data = ''
      rstream.on 'data', (chunk) =>
        data += chunk
      rstream.on 'end', =>
        lines = data.split "\n"
        @processLine(line) for line in lines
        @_log.prevSize = @prevSize
        @_log.save (err) =>
          if err
            console.log(err)
          @watchFile()
    else
      @watchFile()

  watchFile: ->
    watcher = fs.watch @path, (event, filename) =>
      if event is 'change'
        watcher.close()
        @harvest()

  processLine: (line) ->
    year = new Date().getFullYear()
    words = line.split(/[ ]+/)
    timestamp = year + ' ' + words[0..3].join(' ')
    proc = words[4]
    
    if not proc
      return
    
    bracketPos = proc.indexOf('[')
    if bracketPos is -1
      return
    
    procName = proc[0..bracketPos-1]
    id = proc[bracketPos+1...-2]

    if procName is 'pptpd'
      # pptpd is the farther process
      # pptpd start and finish message, the ultimate start and end point of a session
      # console.log line
      if not @activeSessions[id]
          @activeSessions[id] = new sessionModel
          @activeSessions[id].id = id

      if words[9] is 'connection'
        # Start and Finish
        if words[10] is 'started'
          @activeSessions[id].start = Date(timestamp)
          @activeSessions[id].ip = words[7]
        else if words[10] is 'finished'
          @activeSessions[id].end = Date(timestamp)
          @activeSessions[id].duration = @activeSessions[id].end - @activeSessions[id].start
          child = @activeSessions[id].child
          if child isnt '0'
            @activeSessions[id].sent = @activeSessions[child].sent
            @activeSessions[id].received = @activeSessions[child].received
            @activeSessions[id].interface = @activeSessions[child].interface
            delete @activeSessions[child]
          @activeSessions[id].save (err) =>
            if err
              console.log(err)
            console.log(id)
            delete @activeSessions[id]
      if words[7] is 'child'
        # Grab child session ID
        bracketPos = words[8].indexOf('[')
        child = words[8][bracketPos+1...-1]
        @activeSessions[id].child = child
    
    else if procName is 'pppd'
      # console.log line
      if not @activeSessions[id]
          @activeSessions[id] = new sessionModel
          @activeSessions[id].id = id
      if words[5] is 'Sent' and words[8] is 'received'
        @activeSessions[id].sent = Number(words[6])
        @activeSessions[id].received = Number(words[9])
      if words[6] is 'interface'
        @activeSessions[id].interface = words[7]
          
module.exports.LogHarvester = LogHarvester