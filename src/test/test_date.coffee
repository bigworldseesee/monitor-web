moment = require "moment-timezone"

mydate = new Date("2015-06-18T04:20:35Z")
myEDTString = moment(mydate).tz('Asia/Shanghai').format()
console.log myEDTString[0..9]