# index.coffee
mongoose = require 'mongoose'
db = require '../lib/db'


Session = db.Session


exports.index = (req, res) ->
  res.render 'index',
    title : 'User Information'


exports.showinfo = (req, res) ->
  Session.find {'username': req.body.username}, (err, sessions) =>
    console.log err if err
    res.render 'index',
      username: req.body.username
      title : 'User Information'
      sessions : sessions