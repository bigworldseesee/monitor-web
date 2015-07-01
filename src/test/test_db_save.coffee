fs = require 'fs'
mongoose = require 'mongoose'
util = require '../util'


mongoose.connect 'mongodb://localhost/test'
###
TimeStamp = util.TimeStamp
activeSession = {}

Schema = mongoose.Schema
SessionSchema = Schema (
  username: String
  id: String
  interface: String
  ip: String
  start: Date
  end : Date
  duration: Number
  received: Number
  sent: Number
)
Session = mongoose.model('Session', SessionSchema)

MAX_SESSION = 100
num_session = 0

process = (line) ->
  words = line.split(/[ ]+/)
  proc = words[4]
  return if not proc
  bracketPos = proc.indexOf('[')
  return if bracketPos is -1
  procName = proc[0..bracketPos-1]
  id = proc[bracketPos+1...-2]

  if procName is 'pppd'
    num_session += 1
    if num_session > MAX_SESSION
      return
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
        console.log Object.keys(activeSession).length

  ###

logPath = './res/mock.log'
  
watcher = fs.watch logPath, (event, filename) =>
  if event is 'change'
    rstream = fs.createReadStream logPath,
      encoding: 'utf8'
    data = ''
    rstream.on 'data', (chunk) =>
      data += chunk
    rstream.on 'end', =>
      lines = data.split "\n"
      console.log lines


