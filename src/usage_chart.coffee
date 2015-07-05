# usage_chart.coffee

usage = JSON.parse($('#usage').text())
dates = []
count_0 = [0]
count_1 = [0]
count_2 = [0]
count_3 = [0]
count_4 = [0]
count_5_and_above = [0]

for date of usage
  dates.push date.slice(5)
  count_0.push count_0[count_0.length-1] + (usage[date]['0'] ? 0)
  count_1.push count_1[count_1.length-1] + (usage[date]['1'] ? 0)
  count_2.push count_2[count_2.length-1] + (usage[date]['2'] ? 0)
  count_3.push count_3[count_3.length-1] + (usage[date]['3'] ? 0)
  count_4.push count_4[count_4.length-1] + (usage[date]['4'] ? 0)
  count_5_and_above.push  count_5_and_above[count_5_and_above.length-1] + (usage[date]['>4'] ? 0)

count_0[0] = ['0 day']
count_1[0] = ['1 day']
count_2[0] = ['2 day']
count_3[0] = ['3 day']
count_4[0] = ['4 day']
count_5_and_above[0] = ['5 and above']


chart = c3.generate(
  data:
    columns: [
      count_0
      count_1
      count_2
      count_3
      count_4
      count_5_and_above
    ]
    type: 'bar'
    order: null
    groups: [ [
      '0 day'
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



