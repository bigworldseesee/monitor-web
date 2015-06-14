# index.coffee
express = require 'express'
mongoose = require 'mongoose'
db = require '../lib/db'

router = express.Router()
Session = db.Session

router.get '/', (req, res) ->
  Session.find {}, (err, sessions) =>
    console.log err if err
    valid_sessions = []
    for session in sessions
      if session.username
        valid_sessions.push session
        break if valid_sessions.length is 50
    res.render 'index',
      title : 'All users\' Information'
      sessions : valid_sessions


module.exports = router
