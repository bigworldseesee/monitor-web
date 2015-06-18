# index.coffee
express = require 'express'
mongoose = require 'mongoose'
moment = require 'moment-timezone'
db = require '../lib/db'

ONEDAY = 1000 * 60 * 60 * 24

router = express.Router()
Session = db.Session

num_session = 0
ids = []
stats = {}
alldates = []

getChinaDate = (utcStart, utcEnd) ->
  span = [0..Math.floor((utcEnd.getTime() - utcStart.getTime())/ ONEDAY)]
  dates = []
  for offset in span
    dates.push moment(utcStart.getTime() + offset * ONEDAY).tz('Asia/Shanghai').format()[0..9]
  return dates


router.get '/', (req, res) ->
  Session.count {}, (err, count) =>
    console.log err if err
    if count == num_session
      res.render 'index',
        title : 'Daily active users'
        stats : stats
    else
      Session.find {}, (err, sessions) =>
        console.log err if err
        num_session = sessions.length
        for session in sessions
          continue if session.id in ids
          ids.push(session.id)
          for date in getChinaDate(session.start, session.end)
            if not stats[date]
              stats[date] = {}
              alldates.push(date)
              stats[date]['count'] = 1
              stats[date]['users'] = [session.username]
              stats[date]['received'] = session.received
              stats[date]['sent'] = session.sent
            else
              if session.username not in stats[date]['users']
                stats[date]['count'] += 1
                stats[date]['users'].push session.username
              stats[date]['received'] += session.received
              stats[date]['sent'] += session.sent
        alldates.sort()
        res.render 'index',
          title : 'Daily active users'
          alldates : alldates
          stats : stats

module.exports = router
