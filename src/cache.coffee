# cache.coffee

moment = require 'moment-timezone'

ONEDAY = 1000 * 60 * 60 * 24

users = {}
users_summary = {}
timeSeries = {}
usage = {}
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

###
Becareful, there are some users that didn't register. Need to check this in other functions.
Each time a new request coming in, this function gets run first.
This will ensure all newly registered users get initialized.
And before knowing further information, this user is a 0 time user
###
initUser = (accounts) ->
  for account in accounts
    user = account.local.email
    date = account.signup.registerDate
    dateKey = moment(date.getTime()).tz('Asia/Shanghai').format()[0..9]
    # First time see this user, put it into users
    users[user] = {}
    # First time see this user, init users_summary
    users_summary[user] =
      'registerdate': dateKey
      'totaltime': 0
      'sent': 0
      'received': 0
      'count': 0
    # Init usage if that date if not done so.
    # This will ensure the session of a user always see a initialized usage[date].
    # (Well, there are some unregistered users, so still need to check 'undefined', hmmmm)
    # (TODO) manually populate the 4 unregistered users.
    usage[dateKey] ?=
      '0': 0
      '1': 0
      '2': 0
      '3': 0
      '4': 0
      '5': 0  # This is 5 and above
    # Of course you used 0 time, as I haven't seen your session
    usage[dateKey]['0'] += 1
  return

# Add this session to the users[user] information
updateUsers = (date, session, ratio) ->
  user = session.username
  # Update information for users
  users[user] ?= {}
  users[user][date] ?=
    'totaltime': 0
    'sent': 0
    'received': 0
    'count': 0
  users[user][date]['totaltime'] += session.duration * ratio
  users[user][date]['sent'] += (session.sent ? 0) * ratio
  users[user][date]['received'] += (session.received ? 0) * ratio
  users[user][date]['count'] += 1
  # Update information of users_summary
  # This check could gone if all users are registered
  users_summary[user] ?=
    'totaltime': 0
    'sent': 0
    'received': 0
    'count': 0
  users_summary[user]['totaltime'] += session.duration * ratio
  users_summary[user]['sent'] += (session.sent ? 0) * ratio
  users_summary[user]['received'] += (session.received ? 0) * ratio
  users_summary[user]['count'] += 1
  return


updateUsage = (date, session) ->
  user = session.username
  usage[date] ?=
    '0': 0
    '1': 0
    '2': 0
    '3': 0
    '4': 0
    '5': 0
  # Unregistered users never got initalize in initUser, do it here.
  if not users_summary[user]['registerdate'] and users_summary[user]['count'] is 1
    usage[date]['0'] += 1

  # We could count the user usage by how many times or how many days they login.
  # If count by days and it's not the first time login today, we can return now.
  if check_by_day and users[user][date]['count'] isnt 1
    return

  if check_by_day and users[user][date]['count'] is 1
    # First time login today, check how many days hav loggedin
    count = Object.keys(users[user]).length
  else
    # Count by login times
    count = users_summary[user]['count']
    if count < 5
      usage[date][(count-1).toString()] -= 1
      usage[date][count.toString()] += 1
    else if count is 5
      usage[date]['4'] -= 1
      usage[date]['5'] += 1
  return


updateTimeSeries = (date, session, ratio) ->
  # Update information for the time series
  username = session.username
  timeSeries[date] ?=
    'totaltime': 0
    'sent': 0
    'received': 0
    'count': 0
    'users': []
  timeSeries[date]['count'] += 1
  timeSeries[date]['received'] += (session.received ? 0) * ratio
  timeSeries[date]['sent'] += (session.sent ? 0) * ratio
  timeSeries[date]['totaltime'] += session.duration * ratio
  if username not in timeSeries[date]['users']
    timeSeries[date]['users'].push username
  return


exports.users = users
exports.users_summary = users_summary
exports.timeSeries = timeSeries
exports.usage = usage
exports.getConnectionDates = getConnectionDates 
exports.getDurationPercentage = getDurationPercentage
exports.updateTimeSeries = updateTimeSeries
exports.updateUsers = updateUsers
exports.updateUsage = updateUsage
exports.initUser = initUser
