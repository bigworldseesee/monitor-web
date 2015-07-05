# cache.coffee

moment = require 'moment-timezone'

ONEDAY = 1000 * 60 * 60 * 24

users = {}
users_summary = {}
timeseries = {}
usage = {}
recent = []
previousdate = 0
previousinactive = 0
check_by_day = false


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


updateUsers = (date, session, ratio) ->
  # Update information for the user
  user = session.username
  users[user] ?= {}
  if not users_summary[user]
    users_summary[user] = {}
    users_summary[user]['totaltime'] = 0
    users_summary[user]['sent'] = 0
    users_summary[user]['received'] = 0
    users_summary[user]['count'] ?= 0
  if not users[user][date]
    users[user][date] = {}
    users[user][date]['received'] = 0
    users[user][date]['sent'] = 0
    users[user][date]['totaltime'] = 0
  
  users[user][date]['received'] += (session.received ? 0) * ratio
  users[user][date]['sent'] += (session.sent ? 0) * ratio
  users[user][date]['totaltime'] += session.duration * ratio
  users_summary[user]['count'] += 1
  users_summary[user]['totaltime'] += users[user][date]['totaltime']
  users_summary[user]['sent'] += users[user][date]['sent']
  users_summary[user]['received'] += users[user][date]['received']
  return


updateUsage = (date, session) ->
  user = session.username
  usage[date] ?= {}
  if check_by_day 
    if users[user][date]['count'] is 1
      num_days_login = Object.keys(users[user]).length
      if num_days_login is 1
        usage[date]['1'] ?= 0
        usage[date]['1'] += 1
      else if num_days_login < 5
        usage[date][num_days_login.toString()] ?= 0
        usage[date][num_days_login.toString()] += 1
        usage[date][(num_days_login-1).toString()] ?= 0
        usage[date][(num_days_login-1).toString()] -= 1
      else if num_days_login is 5
        usage[date]['4'] ?= 0
        usage[date]['4'] -= 1
        usage[date]['>4'] ?= 0
        usage[date]['>4'] += 1
  else
    count = users_summary[user]['count']
    if count is 1
      usage[date]['1'] ?= 0
      usage[date]['1'] += 1
    else if count < 5
      usage[date][count.toString()] ?= 0
      usage[date][count.toString()] += 1
      usage[date][(count-1).toString()] ?= 0
      usage[date][(count-1).toString()] -= 1
    else if count is 5
      usage[date]['4'] ?= 0
      usage[date]['4'] -= 1
      usage[date]['>4'] ?= 0
      usage[date]['>4'] += 1
  return


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
  return


updateInactiveUser = (newusers) ->
  newusers.sort (a,b) ->
    new Date(a.signup.registerDate) - new Date(b.signup.registerDate)
  for user in newusers
    if not users.hasOwnProperty(user.local.email)
      date = getConnectionDates(user.signup.registerDate, user.signup.registerDate)
      usage[date] ?= {}
      usage[date]['0'] ?= 0
      usage[date]['0'] += 1
  return


updateRegisterDate = (newusers) ->
  for user in newusers
    if users_summary.hasOwnProperty(user.local.email)
      users_summary[user.local.email]['registerdate'] = moment(user.signup.registerDate.getTime()).tz('Asia/Shanghai').format()[0..9]
  return        


exports.users = users
exports.users_summary = users_summary
exports.timeseries = timeseries
exports.usage = usage
exports.recent = recent
exports.check_by_day = check_by_day
exports.getConnectionDates = getConnectionDates 
exports.getDurationPercentage = getDurationPercentage
exports.updateTimeSeries = updateTimeSeries
exports.updateUsers = updateUsers
exports.updateUsage = updateUsage
exports.updateInactiveUser = updateInactiveUser
exports.updateRegisterDate = updateRegisterDate
