# usage_chart.coffee

ONEDAY = 1000*60*60*24

# Plot the usage statistic chart
allUsage = JSON.parse($('#all-usage').text())
allDates = JSON.parse($('#all-dates').text())
groupName = [
      '0 time'
      '1 time'
      '2 times'
      '3 times'
      '4 times'
      '5 times and above'
    ] 

allUsage[0].unshift(groupName[0])
allUsage[1].unshift(groupName[1])
allUsage[2].unshift(groupName[2])
allUsage[3].unshift(groupName[3])
allUsage[4].unshift(groupName[4])
allUsage[5].unshift(groupName[5])
allDates.unshift('date')

n = 1
usagechart = c3.generate(
  bindto: '#usage-chart'
  data:
    x: 'date'
    columns: [
      allDates
      (x for x in allUsage[0] by n)
      (x for x in allUsage[1] by n)
      (x for x in allUsage[2] by n)
      (x for x in allUsage[3] by n)
      (x for x in allUsage[4] by n)
      (x for x in allUsage[5] by n)
    ]
    type: 'bar'
    order: null
    groups: [ groupName ]
  axis:
    x:
      tick:
        centered: true
      type: 'timeseries'
    y: {}
  grid: y: lines: [ { value: 0 } ]
  legend: position: 'top'
)


# Plot the daily active user chart
timeSeries = JSON.parse($('#time-series').text())

dates = ['days']
dau = ['daily active user']
wau = ['weekly active user']
session = ['session count']
weekUsers = {}
weeks = ['weeks']
thisMonday = new Date('2015-05-11')
nextMonday = new Date(thisMonday.getTime() + ONEDAY*7)

# Need to determine the client timezone
if new Date().getTimezoneOffset() > 240  # US
  mondayIndex = 0
else if new Date().getTimezoneOffset() < -420 # China
  mondayIndex = 1

for date, info of timeSeries
  dates.push date
  dau.push info['users'].length
  session.push info['count']

  # Weekly active users
  thisDate = new Date(date)
  if thisDate >= nextMonday
    thisMonday = nextMonday
    nextMonday = new Date(thisMonday.getTime() + ONEDAY*7)
    wau.push Object.keys(weekUsers).length
    weeks.push (new Date(thisMonday.getTime() - ONEDAY)).toISOString()[0..9]
    weekUsers = {}
  for user in info['users']
    if user of weekUsers
      weekUsers[user] += 1
    else
      weekUsers[user] = 1

wau.push Object.keys(weekUsers).length
weeks.push date

active_user_chart = c3.generate(
  bindto: '#active-user-chart'
  data:
    xs:
      'daily active user': 'days'
      'weekly active user': 'weeks'
    columns: [
      dates
      dau
      weeks
      wau
    ]
  axis:
    x:
      type: 'timeseries'
)
