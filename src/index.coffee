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


router = express.Router()

# Always update the gobal variables first upon request
router.use (req, res, next) ->
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
    "start" :
      "$gte" : lastcheck
    "active" : false
  }, (err, sessions) =>
    throw err if err
    sessions.sort (a,b) ->
      new Date(a.start) - new Date(b.start)

    # Update recent sessions, users and timeseries 
    for session in sessions
      # Update recent sessions
      if recentSession.length is 100
        recentSession.pop()
      recentSession.unshift {
        'username' : session.username
        'start': moment(session.start).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')
        'end': moment(session.end).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')
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

    lastcheck = new Date()
    next()


router.get '/', (req, res) ->
    res.render 'index',
      title : 'Daily active users'
      users_summary : cache.users_summary
      timeseries : cache.timeseries
      allUsage : allUsage
      allDates : allDates
      recentSession : recentSession
      currentTime : moment(new Date()).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')


module.exports = router
