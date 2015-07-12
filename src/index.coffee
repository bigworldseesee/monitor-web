# index.coffee

express = require 'express'
mongoose = require 'mongoose'
moment = require 'moment-timezone'
cache = require '../cache'
db = require '../model/db'
Session = db.Session
User = db.User
lastcheck = 0
recentSession = []
allDates = []
allUsage = [[0], [0], [0], [0], [0], [0]]
updating = false

router = express.Router()

# Always update the gobal variables first upon request
router.use (req, res, next) ->
  if updating
    showPage(res, res) # Cache data is updating, don't update here.
  updating = true
  Account = dbRegister.model('User');
  Account.find {
    "signup.registerDate" :
      "$gte" : lastcheck
  }, (err, accounts) =>
    throw err if err
    cache.initUser accounts
    next()


# Always update the gobal variables first upon request
router.use (req, res, next) ->
  Session = dbMonitor.model('Session');
  Session.find {
    "end" :
      "$gte" : lastcheck
    "active" : false
  }, (err, sessions) =>
    throw err if err
    sessions.sort (a,b) ->
      new Date(a.start) - new Date(b.start)
    # Update recent sessions, users and timeseries 
    for session in sessions
      # Update recent sessions
      start_key = moment(session.start).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')
      end_key = moment(session.end).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')
      found = false
      for s in recentSession
        if s['start'] < start_key
          break
        if not s['end'] and s['id'] is session.id and s['username'] is session.username and s['start'] is start_key
          s['end'] = end_key
          s['duration'] = session.duration
          s['sent'] = session.sent
          s['received'] = session.received
          found = true
          console.log "found"
          break
      if found is false
        recentSession.pop() if recentSession.length is 100
        recentSession.unshift {
          'id' : session.id
          'username' : session.username
          'start': start_key
          'end': end_key
          'duration': session.duration
          'sent': session.sent
          'received': session.received
        }
      # Update users, usage, timeseries 
      dates = cache.getConnectionDates session.start, session.end
      # (TODO) check if bug here for ratio.
      ratios = cache.getDurationPercentage session.start, session.end
      for date, i in dates
        cache.updateUsers date, session, ratios[i]
        cache.updateUsage date, session  # updateUsage() has to run after updateUsers()
        cache.updateTimeSeries date, session, ratios[i]
        if date not in allDates
          allDates.push date
    # allUsage[0..length-2] are already fixed, no need to update, but need to update allUsage[-1]
    # u0  u1  u2  u3  u4
    # d0  d1  d2  d3  d4  d5  d6
    len1 = allUsage[0].length
    len2 = allDates.length
    for i in [0..5]
      allUsage[i][len1-1] = cache.usage[allDates[len1-1]][i.toString()]
      for j in [len1..len2-1] by 1
        allUsage[i].push cache.usage[allDates[j]][i.toString()]
      for j in [len1-1..len2-1] by 1
        allUsage[i][j] += allUsage[i][j-1] ? 0
    next()

# Get currently login user
router.use (req, res, next) ->
  Session = dbMonitor.model('Session');
  Session.find {
    "start" :
      "$gte" : lastcheck
    "active" : true
  }, (err, sessions) =>
    throw err if err
    sessions.sort (a,b) ->
      new Date(a.start) - new Date(b.start)
    for session in sessions
      if recentSession.length is 100
        recentSession.pop()
      recentSession.unshift {
        'id' : session.id
        'username' : session.username
        'start': moment(session.start).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')
      }
    lastcheck = new Date()
    updating = false;
    next()

router.get '/', (req, res) ->
  showPage(req, res)

showPage = (req, res) ->
    res.render 'index',
      title : 'Daily active users'
      users_summary : cache.users_summary
      timeSeries : cache.timeSeries
      allUsage : allUsage
      allDates : allDates
      recentSession : recentSession
      currentTime : moment(new Date()).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')


module.exports = router
