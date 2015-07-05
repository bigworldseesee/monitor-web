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

router = express.Router()

prettyDate = (date) ->
  d = date.getDate()
  monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  m = date.getMonth()
  y = date.getFullYear()
  h = date.getHours()
  min = date.getMinutes()
  [y, m, d].join('-') + ' ' + h + ':' + min


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
      dates = cache.getConnectionDates session.start, session.end
      ratios = cache.getDurationPercentage session.start, session.end
      for date, i in dates
        cache.updateUsers date, session, ratios[i]
        cache.updateUsage date, session  # updateUsage() has to run after updateUsers()
        cache.updateTimeSeries date, session, ratios[i]
    next()


# Always update the gobal variables first upon request
router.use (req, res, next) ->
  Account = dbRegister.model('User');
  Account.find {
    "signup.registerDate" :
      "$gte" : lastcheck
  }, (err, accounts) =>
    throw err if err
    cache.updateRegisterDate accounts
    cache.updateInactiveUser accounts
    lastcheck = new Date()
    next()


router.get '/', (req, res) ->
    res.render 'index',
      title : 'Daily active users'
      users_summary : cache.users_summary
      timeseries : cache.timeseries
      usage: cache.usage
      recentSession: recentSession
      currentTime: moment(new Date()).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')


module.exports = router
