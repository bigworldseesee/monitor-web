# cache.coffee

moment = require 'moment-timezone'

ONEDAY = 1000 * 60 * 60 * 24


# Returns dates in China time.
exports.getConnectionDates = (utcStart, utcEnd) ->
  span = [0..Math.floor((utcEnd.getTime() - utcStart.getTime()) / ONEDAY)]
  dates = []
  for offset in span
    dates.push moment(utcStart.getTime() + offset * ONEDAY).tz('Asia/Shanghai').format()[0..9]
  return dates


# Returns the duration percentage for each day.
exports.getDurationPercentage = (utcStart, utcEnd) ->
  totalDuration = utcEnd.getTime() - utcStart.getTime()
  if utcEnd < utcStart.setHours(23, 59, 59, 999)
    return [1]

  result = []
  day1 = utcStart.setHours(23, 59, 59, 999) - utcStart
  result.push(day1 / totalDuration)
  remaining = totalDuration - day1
  while remaining > 0
    if remaining > ONEDAY
      result.push ONEDAY/totalDuration
      remaining -= ONEDAY
    else
      result.push remaining/totalDuration
      return result


exports.updateTimeSeries = (date, session, ratio) ->
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


exports.updateUsers = (date, session, ratio) ->
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


exports.updateUsage = (date, session, previousDate) ->
  # Initialize daily usage
  if not usage[date]
    if Object.keys(usage).length is 0
      usage[date] = 
        '1': 0
        '2': 0
        '3': 0
        '4': 0
        '>4': 0
    else
      usage[date] = 
        '1': usage[previousDate]['1']
        '2': usage[previousDate]['2']
        '3': usage[previousDate]['3']
        '4': usage[previousDate]['4']
        '>4': usage[previousDate]['>4']
  user = session.username
  users[user] ?= {}
  if not users[user][date]
    num_days_login = Object.keys(users[user]).length
    if num_days_login is 0
      usage[date]['1'] += 1
    else if num_days_login < 4
      usage[date][num_days_login.toString()] -= 1
      usage[date][(num_days_login+1).toString()] += 1
    else if num_days_login is 4
      usage[date]['4'] -= 1
      usage[date]['>4'] += 1
  return date


