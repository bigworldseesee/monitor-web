# index.coffee
express = require 'express'
mongoose = require 'mongoose'
db = require '../lib/db'

router = express.Router()
Session = db.Session

router.get '/', (req, res) ->
  res.render 'user',
    title : 'Your information'
    sessions : []

router.post '/', (req, res) ->
  Session.find {'username': req.body.username}, (err, sessions) =>
    console.log err if err
    if sessions
      for session in sessions
        session.duration = 0 if not session.duration
        session.sent = 0 if not session.sent
        session.received = 0 if not session.received
      res.render 'user',
        username: req.body.username
        title : 'User Information'
        sessions : sessions

module.exports = router;