# usage_chart.coffee

unit = 'time'

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

count_0[0] = ['0 ' + unit]
count_1[0] = ['1 ' + unit]
count_2[0] = ['2 ' + unit]
count_3[0] = ['3 ' + unit]
count_4[0] = ['4 ' + unit]
count_5_and_above[0] = ['5 and above']


usage-chart = c3.generate(
  bindto: '#usage_chart'
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
      '0 ' + unit
      '1 ' + unit
      '2 ' + unit
      '3 ' + unit
      '4 ' + unit
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



