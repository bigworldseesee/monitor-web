# index.coffee
express = require 'express'
mongoose = require 'mongoose'
db = require '../model/db'

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
      sessions.sort((a, b) ->
        keyA = new Date(a.start)
        keyB = new Date(b.start)
        return -1 if keyA < keyB
        return 1 if keyA > keyB
        return 0
      )
      res.render 'user',
        username: req.body.username
        title : 'User Information'
        sessions : sessions

module.exports = router;
