# usage_chart.coffee

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

n = 2
usagechart = c3.generate(
  bindto: '#usage-chart'
  data:
    columns: [
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
        label: 'Date'
      type: 'category'
      categories: (x[-5..] for x in allDates by n)
    y: {}
  grid: y: lines: [ { value: 0 } ]
  legend: position: 'right')



