# db.coffee

mongoose = require 'mongoose'

Schema = mongoose.Schema

SessionSchema = Schema (
  version: Number
  id: String
  active: Boolean
  username: String
  interface: String
  ip: String
  start: Date
  end : Date
  duration: Number
  received: Number
  sent: Number
)

module.exports.Session = mongoose.model('Session', SessionSchema)
