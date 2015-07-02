# index.coffee

express = require 'express'
mongoose = require 'mongoose'
moment = require 'moment-timezone'
db = require '../model/db'

ONEDAY = 1000 * 60 * 60 * 24

router = express.Router()
Session = db.Session

num_session = 0
_ids = []
stats = {}
alldates = []
users = {}
usage = {}

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
        alldates : alldates
        usage : usage
    else
      Session.find {}, (err, sessions) =>
        console.log err if err
        num_session = sessions.length
        for session in sessions
          continue if session._id in _ids or session.active 
          _ids.push(session._id)
          for date in getChinaDate(session.start, session.end)
            if not stats[date]
              stats[date] = {}
              alldates.push(date)
              stats[date]['count'] = 1
              stats[date]['users'] = [session.username]
              stats[date]['received'] = if session.received then session.received else 0
              stats[date]['sent'] = if session.sent then session.sent else 0
            else
              if session.username not in stats[date]['users']
                stats[date]['count'] += 1
                stats[date]['users'].push session.username
              stats[date]['received'] += if session.received then session.received else 0
              stats[date]['sent'] += if session.sent then session.sent else 0
        alldates.sort()
        alldates.reverse()

        usage['1'] = {}
        usage['1']['count'] = 0
        usage['1']['cumu'] = 0
        for date, v of stats
          for user in v['users']
            if users[user]
              count = users[user]
              usage[count.toString()]['count']--
              count++
              users[user] = count
              if usage[count.toString()]
                usage[count.toString()]['count']++
              else
                usage[count.toString()] = {}
                usage[count.toString()]['count'] = 1
            else
              users[user] = 1
              usage['1']['count'] += 1
        for days, info of usage
          if days is '1'
            cumu = usage[days]['count']
          else
            cumu += usage[days]['count']
          usage[days]['cumu'] = cumu

        for user, count of users
          if usage[count.toString()]['users']
            usage[count.toString()]['users'].push(user)
          else
            usage[count.toString()]['users'] = [user]

        res.render 'index',
          title : 'Daily active users'
          alldates : alldates
          stats : stats
          usage: usage
module.exports = router
