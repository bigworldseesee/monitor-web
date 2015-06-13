fs = require 'fs'
events = require 'events'
mongoose = require 'mongoose'
database = require './database'
{spawn, exec} = require 'child_process'

# create the model for users and expose it to our app
userModel = database.userModel
logModel = database.logModel
sessionModel = database.sessionModel
dauModel = database.dauModel

WAIT_TIME_FOR_LAST = 1000
DEFAULT_LAST_NUMBER = 10


class DAUCache extends events.EventEmitter
  constructor: ->
    @queue = {}

  add: (username, timestamp) ->
    ymd = timestamp.year + timestamp.month + timestamp.day
    if not @queue[ymd]
      @queue[ymd] = [username]
      @emit 'start', (timestamp)
      return
    if username not in @queue[ymd]
      @queue[ymd].push username

  process: (timestamp) ->
    ymd = timestamp.year + timestamp.month + timestamp.day
    if @queue[ymd][0]
      console.log @queue[ymd]
      username = @queue[ymd][0]
      dauModel.findOne {'ymd': ymd}, (err, dau) =>
        throw err if err
        if dau
          if username in dau.username
            @queue[ymd].splice(0, 1)
            @process timestamp
          else
            dau.username.push username
        else
          dau = new dauModel
          dau.ymd = ymd
          dau.username = [username]
        dau.save (err) =>
          throw err if err
          @queue[ymd].splice(0, 1)
          @process timestamp


class TimeStamp
  constructor: (@year, @month, @day, @time) ->

  toDate: ->
    new Date([@year, @month, @day, @time].join(' '))


class LogHarvester
  constructor: (@path) ->
    @Sessions = {}
    @dau = new DAUCache()

  run: ->
    @dau.on 'start', (timestamp) =>
      @dau.process timestamp

    logModel.findOne {'name': @path},  (err, log) =>
      throw err if err
      if not log
        log = new logModel
        log.name = @path
        log.prevSize = 0
        log.save (err) =>
        throw err if err
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
          throw err if err
          @watchFile()
    else
      @watchFile()

  watchFile: ->
    watcher = fs.watch @path, (event, filename) =>
      if event is 'change'
        watcher.close()
        @harvest()

  _setUsername: (id, timestamp, mode='realtime') ->
    if mode is 'realtime'
      command = spawn('last', ['-#{DEFAULT_LAST_NUMBER}'])
    else if mode is 'repair'
      command = spawn('last')

    data = ''
    command.stdout.on 'data', (chunk) =>
      data += chunk
    last_command.on 'close', =>
      records = data.split "\n"
      if @Sessions[id]
        for record in records
          words = record.split(/[ ]+/)
          if words[2] is @Sessions[id].ip and words[4] is month and words[5] is day and words[6] is time[0..4]
            @Sessions[id].username = words[0]
            @dau.add words[0], timestamp
      else
        sessionModel.findOne {'id': @id},  (err, session) =>
          throw err if err
          throw id + ' not found' if not session
          for record in records
            words = record.split(/[ ]+/)
            if words[2] is session.ip and words[4] is month and words[5] is day and words[6] is time[0..4]
              session.username = words[0] 
              session.save (err) =>
                throw err if err
              @dau.add words[0], timestamp

  _setUsernameMock: (id, timestamp, mode='realtime') ->
    year = timestamp.year
    month = timestamp.month
    day = timestamp.day
    time = timestamp.time

    rstream = fs.createReadStream 'test/last.txt',
      encoding: 'utf8'
    data = ''
    rstream.on 'data', (chunk) =>
      data += chunk
    rstream.on 'end', =>
      records = data.split "\n"
      if @Sessions[id]
        for record in records
          words = record.split(/[ ]+/)
          if words[2] is @Sessions[id].ip and words[4] is month and words[5] is day and words[6] is time[0..4]
            @Sessions[id].username = words[0]
            @dau.add words[0], timestamp

      else
        sessionModel.findOne {'id': id},  (err, session) =>
          throw err if err
          throw id + ' not found' if not session
          for record in records
            words = record.split(/[ ]+/)
            if words[2] is session.ip and words[4] is month and words[5] is day and words[6] is time[0..4]
              session.username = words[0]
              session.save (err) =>
                throw err if err
              @dau.add words[0], timestamp


  _processPPTP: (words, id) ->
    timestamp = new TimeStamp(new Date().getFullYear(), words[0], words[1], words[2])

    if not @Sessions[id]
      @Sessions[id] = new sessionModel
      @Sessions[id].id = id

    if words[9] is 'connection' and words[10] is 'started'
      @Sessions[id].start = timestamp.toDate()
      @Sessions[id].ip = words[7]
      setTimeout =>
        @_setUsernameMock id, timestamp
      , 1000
      
    if words[9] is 'connection' and words[10] is 'finished'
      @Sessions[id].end = timestamp.toDate()
      @Sessions[id].duration = @Sessions[id].end - @Sessions[id].start
      child = @Sessions[id].child
      if child isnt '0'
        @Sessions[id].sent = @Sessions[child].sent
        @Sessions[id].received = @Sessions[child].received
        @Sessions[id].interface = @Sessions[child].interface
      @Sessions[id].save (err) =>
        throw err if err
        delete @Sessions[id]
    
    if words[7] is 'child'
      # Grab child session ID
      bracketPos = words[8].indexOf('[')
      child = words[8][bracketPos+1...-1]
      @Sessions[id].child = child

  _processPPP: (words, id) ->
    if not @Sessions[id]
        @Sessions[id] = new sessionModel
        @Sessions[id].id = id
    if words[5] is 'Sent' and words[8] is 'received'
      @Sessions[id].sent = Number(words[6])
      @Sessions[id].received = Number(words[9])
    if words[6] is 'interface'
      @Sessions[id].interface = words[7]
    if words[4] is 'Exit.'
      delete @Sessions[child]

  processLine: (line) ->
    words = line.split(/[ ]+/)
    proc = words[4]
    return if not proc
    bracketPos = proc.indexOf('[')
    return if bracketPos is -1

    procName = proc[0..bracketPos-1]
    id = proc[bracketPos+1...-2]
    @_processPPTP words, id if procName is 'pptpd'
    @_processPPP words, id if procName is 'pppd'


module.exports.LogHarvester = LogHarvester