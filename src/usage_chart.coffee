# usage_chart.coffee

usage = JSON.parse($('#usage').text())
dates = []
count_1 = [ '1 day' ]
count_2 = [ '2 day' ]
count_3 = [ '3 day' ]
count_4 = [ '4 day' ]
count_5_and_above = [ '5 and above' ]

for date of usage
  dates.push date.slice(5)
  count_1.push usage[date]['1']
  count_2.push usage[date]['2']
  count_3.push usage[date]['3']
  count_4.push usage[date]['4']
  count_5_and_above.push usage[date]['>4']


chart = c3.generate(
  data:
    columns: [
      count_1
      count_2
      count_3
      count_4
      count_5_and_above
    ]
    type: 'bar'
    order: null
    groups: [ [
      '1 day'
      '2 day'
      '3 day'
      '4 day'
      '5 and above'
    ] ]
  axis:
    x:
      tick:
        centered: true
        label: 'Date'
      type: 'category'
      categories: dates
    y: {}
  grid: y: lines: [ { value: 0 } ]
  legend: position: 'right')



