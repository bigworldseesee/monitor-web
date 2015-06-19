# recent.coffee
express = require 'express'
mongoose = require 'mongoose'
db = require '../lib/db'

router = express.Router()
Session = db.Session

router.get '/', (req, res) ->
  Session.find {}, (err, sessions) =>
    console.log err if err
    sessions.sort((a, b) ->
      keyA = new Date(a.start)
      keyB = new Date(b.start)
      return -1 if keyA > keyB
      return 1 if keyA < keyB
      return 0
    )
    res.render 'recent',
      title : 'Recent users'
      sessions : sessions[0..50]



module.exports = router;