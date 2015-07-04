# index.coffee

express = require 'express'
mongoose = require 'mongoose'
moment = require 'moment-timezone'
db = require '../model/db'
cache = require '../cache'


router = express.Router()


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
    # Update users and timeseries 
    for session in sessions
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


module.exports = router
