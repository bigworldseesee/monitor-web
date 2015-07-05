# cache.coffee

moment = require 'moment-timezone'

ONEDAY = 1000 * 60 * 60 * 24

users = {}
timeseries = {}
usage = {}
recent = []
previousdate = 0
previousinactive = 0


# Returns dates in China time.
getConnectionDates = (utcStart, utcEnd) ->
  span = [0..Math.floor((utcEnd.getTime() - utcStart.getTime()) / ONEDAY)]
  dates = []
  for offset in span
    dates.push moment(utcStart.getTime() + offset * ONEDAY).tz('Asia/Shanghai').format()[0..9]
  return dates


# Returns the duration percentage for each day.
getDurationPercentage = (utcStart, utcEnd) ->
  tmp = new Date utcStart.getTime() 
  tmp.setHours(23, 59, 59, 999)
  totalDuration = utcEnd.getTime() - utcStart.getTime()
  if utcEnd < tmp
    return [1]

  result = []
  day1 = tmp - utcStart
  result.push day1 / totalDuration
  remaining = totalDuration - day1
  while remaining > 0
    if remaining > ONEDAY
      result.push ONEDAY/totalDuration
      remaining -= ONEDAY
    else
      result.push remaining/totalDuration
      return result


updateTimeSeries = (date, session, ratio) ->
  # Update information for the time series
  timeseries[date] ?= {}
  timeseries[date]['count'] ?= 0
  timeseries[date]['received'] ?= 0
  timeseries[date]['sent'] ?= 0
  timeseries[date]['totaltime'] ?= 0
  timeseries[date]['users'] ?= []
  timeseries[date]['count'] += 1
  timeseries[date]['received'] += (session.received ? 0) * ratio
  timeseries[date]['sent'] += (session.sent ? 0) * ratio
  timeseries[date]['totaltime'] += session.duration * ratio
  if session.username not in timeseries[date]['users']
    timeseries[date]['users'].push session.username


updateUsers = (date, session, ratio) ->
  # Update information for the user
  user = session.username
  users[user] ?= {}
  if not users[user][date]
    users[user][date] = {}
    users[user][date]['received'] = 0
    users[user][date]['sent'] = 0
    users[user][date]['totaltime'] = 0
  users[user][date]['received'] += (session.received ? 0) * ratio
  users[user][date]['sent'] += (session.sent ? 0) * ratio
  users[user][date]['totaltime'] += session.duration * ratio


updateUsage = (date, session) ->
  user = session.username
  users[user] ?= {}
  usage[date] ?= {}
  if not users[user][date]
    num_days_login = Object.keys(users[user]).length
    if num_days_login is 0
      usage[date]['1'] ?= 0
      usage[date]['1'] += 1
    else if num_days_login < 4
      usage[date][num_days_login.toString()] ?= 0
      usage[date][num_days_login.toString()] -= 1
      usage[date][(num_days_login+1).toString()] ?= 0
      usage[date][(num_days_login+1).toString()] += 1
    else if num_days_login is 4
      usage[date]['4'] ?= 0
      usage[date]['4'] -= 1
      usage[date]['>4'] ?= 0
      usage[date]['>4'] += 1


updateInactiveUser = (newusers) ->
  newusers.sort (a,b) ->
    new Date(a.signup.registerDate) - new Date(b.signup.registerDate)
  for user in newusers
    if not users.hasOwnProperty(user.local.email)
      date = getConnectionDates(user.signup.registerDate, user.signup.registerDate)
      usage[date] ?= {}
      usage[date]['0'] ?= 0
      usage[date]['0'] += 1


exports.users = users
exports.timeseries = timeseries
exports.usage = usage
exports.recent = recent
exports.getConnectionDates = getConnectionDates 
exports.getDurationPercentage = getDurationPercentage
exports.updateTimeSeries = updateTimeSeries
exports.updateUsers = updateUsers
exports.updateUsage = updateUsage
exports.updateInactiveUser = updateInactiveUser
