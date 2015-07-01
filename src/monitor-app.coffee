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

config = require './lib/config'
mongoose.connect config.appUrl

app = express()

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.set 'port', process.env.PORT || 12345
app.use logger('dev')
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use require('stylus').middleware(__dirname + '/public')
app.use express.static path.join(__dirname, 'public')

app.locals.sprintf = require('sprintf').sprintf
app.locals.moment = require 'moment-timezone'
app.locals.format = '%1.1f'


app.use '/', routes
app.use '/user', user
app.use '/recent', recent


http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
