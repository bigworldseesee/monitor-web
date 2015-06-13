# user.coffee
mongoose = require 'mongoose'


userSchema = mongoose.Schema(
  email : String
  closed_sessions : [String]
  active_sessions: [String]
)

logSchema = mongoose.Schema(
  name: String
  prevSize : Number
)

sessionSchema = mongoose.Schema(
  username: String
  id: String
  ip: String
  child: String
  start: Date
  end : Date
  duration: Number
  received: Number
  sent: Number
  interface: String
)

dauSchema = mongoose.Schema(
  ymd: String
  username: [String]
)

# create the model for users and expose it to our app
module.exports.userModel = mongoose.model('userModel', userSchema)
module.exports.logModel = mongoose.model('logModel', logSchema)
module.exports.sessionModel = mongoose.model('sessionModel', sessionSchema)
module.exports.dauModel = mongoose.model('dauModel', dauSchema)