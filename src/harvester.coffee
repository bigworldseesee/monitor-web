fs = require 'fs'
events = require 'events'
mongoose = require 'mongoose'

db = require './db'
Session = db.Session
config = require './config'
logPath = config.logPath

class Harvester extends events.EventEmitter

  constructor: ->
    @prevSize = 0
    Session.remove 'version':1, (err) =>
      @emit 'ready'

  harvest: ->
    @currSize = fs.statSync(logPath).size
    rstream = fs.createReadStream logPath,
      encoding: 'utf8'
      start: @prevSize
      end: @currSize
    @prevSize = @currSize
    data = ''
    rstream.on 'data', (chunk) =>
      data += chunk
    rstream.on 'end', =>
      @lines = data.split "\n"
      @process(0, @lines.length)

  process: (idx, num_lines) ->
    if idx == num_lines
      @emit 'finish'
      return
    line = @lines[idx]
    console.log line
    words = line.split(/[ ]+/)
    proc = words[3]
    bracketPos = proc.indexOf('[')
    procName = proc[0..bracketPos-1]
    id = proc[bracketPos+1...-2]
    timestamp = new Date([words[0], words[1], words[2]].join(' '))
    if words[4] is 'START'
      session = new Session
      session.version = 1
      session.active = true
      session.start = timestamp
      session.id = id
      session.interface = words[5]
      session.username = words[6]
      session.ip = words[7]
      session.save (err) =>
        throw err if err
        @process(idx+1, num_lines)
    else if words[4] is 'END'
      Session.findOne
        'id': id
        'active': true, (err, session) =>
          throw err if err
          session.active = false
          session.end = timestamp
          session.sent = words[9]
          session.received = words[12]
          session.duration = words[16]
          session.save (err) =>
            throw err if err
            @process(idx+1, num_lines)


module.exports.Harvester = Harvester
