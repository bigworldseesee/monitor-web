fs = require 'fs'
events = require 'events'
mongoose = require 'mongoose'
spawn = require('child_process').spawn
db = require './db'
util = require './util'

User = db.User
Syslog = db.Syslog
Session = db.Session
FileWatcher = util.FileWatcher
TimeStamp = util.TimeStamp

activeSession = {}
# (TODO) Fix: if the server restarts, some active sessions could be lost.


# Havester collects the changes from syslog and
# combines the log from `last` to form the session information
class Harvester extends events.EventEmitter

  constructor: (@logPath, @istest=false) ->
    Syslog.findOne {'name': @logPath},  (err, syslog) =>
      throw err if err
      if not syslog
        syslog = new Syslog
        syslog.path = @logPath
        syslog.checkedSize = 0
      @_syslog = syslog
      # @prevSize = @_syslog.checkedSize
      @prevSize = 0
      syslog.save (err) =>
        throw err if err
      # Setup done, ready to harvest
      command = spawn('last', ['-w'])
      data = ''
      command.stdout.on 'data', (chunk) =>
        data += chunk
      command.on 'close', =>
        fs.writeFileSync('./last.txt', data);
        @emit 'ready'


  harvest: ->
    @currSize = fs.statSync(@logPath).size
    rstream = fs.createReadStream @logPath,
      encoding: 'utf8'
      start: @prevSize
      end: @currSize
    @prevSize = @currSize
    data = ''
    rstream.on 'data', (chunk) =>
      data += chunk
    rstream.on 'end', =>
      lines = data.split "\n"
      @process line for line in lines
      if @istest
        util.sleep 3000
        console.log lines 
      @_syslog.prevSize = @prevSize
      @_syslog.save (err) =>
        throw err if err
      # Current log processing complete, notify the world.
      @emit 'finish'


  process: (line) ->
    words = line.split(/[ ]+/)
    proc = words[4]
    return if not proc
    bracketPos = proc.indexOf('[')
    return if bracketPos is -1
    procName = proc[0..bracketPos-1]
    id = proc[bracketPos+1...-2]
    @_processPPP words, id if procName is 'pppd'


  _processPPP: (words, id) ->
    timestamp = new TimeStamp(new Date().getFullYear(), words[0], words[1], words[2])
    if not activeSession[id]
      activeSession[id] = new Session
      activeSession[id].id = id

    if words[5] is 'Plugin'
      activeSession[id].start = timestamp.toDate()

    else if words[6] is 'interface'
        activeSession[id].interface = words[7]

    else if words[5] is 'peer' and words[6] is 'from'
      activeSession[id].ip = words[9]

    else if words[5] is 'remote' and words[6] is 'IP'
      @_setUsernameWrapper id, timestamp # This is a async function

    else if words[5] is 'Sent' and words[8] is 'received'
      activeSession[id].sent = Number(words[6]) / 1024 / 1024
      activeSession[id].received = Number(words[9]) / 1024 / 1024

    else if words[5] is 'Exit.'
      activeSession[id].end = timestamp.toDate()
      if activeSession[id].end and activeSession[id].start
        activeSession[id].duration = (activeSession[id].end - activeSession[id].start) / 1000 / 60
      activeSession[id].save (err) =>
        throw err if err
        delete activeSession[id]

  _setUsername: (id, data, timestamp) ->
    year = timestamp.year
    month = timestamp.month
    day = timestamp.day
    time = timestamp.time
    records = data.split "\n"
    if activeSession[id]
      for record in records
        words = record.split(/[ ]+/)
        if words[2] is activeSession[id].ip and words[4] is month and words[5] is day and words[6] is time[0..4]
          activeSession[id].username = words[0]
    else
      Session.findOne {'id': id},  (err, session) =>
        throw err if err
        for record in records
          words = record.split(/[ ]+/)
          if words[2] is session.ip and words[4] is month and words[5] is day and words[6] is time[0..4]
            session.username = words[0]
            session.save (err) =>
              throw err if err

  _setUsernameWrapper: (id, timestamp) ->
    currDate = new Date()
    if currDate - timestamp.toDate() < 10000 # If the syslog and current time larger than 10 seconds
      command = spawn('last', ['-w', '-10'])
      data = ''
      command.stdout.on 'data', (chunk) =>
        data += chunk
      command.on 'close', =>
        @_setUsername id, data, timestamp
    else
      rstream = fs.createReadStream './last.txt',
        encoding: 'utf8'
      data = ''
      rstream.on 'data', (chunk) =>
        data += chunk
      rstream.on 'end', =>
        @_setUsername id, data, timestamp


  _setUsernameMock: (id, timestamp, mode='realtime') ->
    year = timestamp.year
    month = timestamp.month
    day = timestamp.day
    time = timestamp.time

    rstream = fs.createReadStream './res/last.txt',
      encoding: 'utf8'
    data = ''
    rstream.on 'data', (chunk) =>
      data += chunk
    rstream.on 'end', =>
      records = data.split "\n"
      if activeSession[id]
        for record in records
          words = record.split(/[ ]+/)
          if words[2] is activeSession[id].ip and words[4] is month and words[5] is day and words[6] is time[0..4]
            activeSession[id].username = words[0]
      else
        Session.findOne {'id': id},  (err, session) =>
          throw err if err
          for record in records
            words = record.split(/[ ]+/)
            if words[2] is session.ip and words[4] is month and words[5] is day and words[6] is time[0..4]
              session.username = words[0]
              session.save (err) =>
                throw err if err


module.exports.Harvester = Harvester
