# app.coffee

express = require 'express'
http = require 'http'
path = require 'path'
favicon = require 'serve-favicon'
logger = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
mongoose = require 'mongoose'


routes = require './routes/index'
user = require './routes/user'
recent = require './routes/recent'

loader = require './model/loader'
config = require './model/config'
mongoose.connect config.url


app = express()

app.use express.static path.join(__dirname, 'public')
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.set 'port', process.env.PORT || 12345
app.use logger('dev')
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use require('stylus').middleware(__dirname + '/public')

app.locals.sprintf = require('sprintf').sprintf
app.locals.moment = require 'moment-timezone'
app.locals.format = '%1.1f'

global.users = {}
global.timeseries = {}
global.usage = {}
global.lastCheck = 0
global.previousDate = 0

app.use '/', routes
app.use '/user', user
app.use '/recent', recent


http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
