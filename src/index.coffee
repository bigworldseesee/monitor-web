# index.coffee

express = require 'express'
mongoose = require 'mongoose'
moment = require 'moment-timezone'
db = require '../model/db'
cache = require '../cache'


router = express.Router()

prettyDate = (date) ->
  d = date.getDate()
  monthNames = [
    'Jan'
    'Feb'
    'Mar'
    'Apr'
    'May'
    'Jun'
    'Jul'
    'Aug'
    'Sep'
    'Oct'
    'Nov'
    'Dec'
  ]
  m = date.getMonth()
  y = date.getFullYear()
  h = date.getHours()
  min = date.getMinutes()
  [
    y
    m
    d
  ].join('-') + ' ' + h + ':' + min


# Always update the gobal variables first upon request
router.use (req, res, next) ->
  Session = db.Session
  Session.find {
    "start" :
      "$gte" : lastCheck
    "active" : false
  }, (err, sessions) =>
    throw err if err
    sessions.sort (a,b) ->
      new Date(a.start) - new Date(b.start)

    # Update recent sessions, users and timeseries 
    for session in sessions
      if recent.length is 50
        recent.pop()
      recent.unshift {
        'username' : session.username
        'start': moment(session.start).tz('Asia/Shanghai').format('YYYY-MM-DD HH:mm')
        'duration': session.duration
        'sent': session.sent
        'received': session.received
      }
      dates = cache.getConnectionDates session.start, session.end
      ratios = cache.getDurationPercentage session.start, session.end
      for date, i in dates
        previousDate = cache.updateUsage date, session, previousDate
        cache.updateUsers date, session, ratios[i]
        cache.updateTimeSeries date, session, ratios[i]
    lastCheck = new Date()
    next()


router.get '/', (req, res) ->
    res.render 'index',
      title : 'Daily active users'
      users : users
      timeseries : timeseries
      usage: usage
      recent: recent


module.exports = router
