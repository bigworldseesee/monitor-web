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


UserSchema = mongoose.Schema (
  signup:
    registerDate: Date
    confirmDate: Date
  attributes:
    groupId: [ Number ]
    OSId: [ Number ]
  local:
    email: String
    password: String
  facebook:
    id: String
    token: String
    email: String
    name: String
  twitter:
    id: String
    token: String
    displayName: String
    username: String
  google:
    id: String
    token: String
    email: String
    name: String
)

exports.Session = mongoose.model('Session', SessionSchema)
exports.User = mongoose.model('User', UserSchema)
