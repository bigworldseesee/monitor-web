mongoose = require 'mongoose'
express = require 'express'
routes = require './routes'
http = require 'http'
path = require 'path'

mongoose.connect 'mongodb://localhost/bwss-monitor'

app = express()

app.locals.sprintf = require('sprintf').sprintf;

app.locals.format = "%1.1f";

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('stylus').middleware(__dirname + '/public')
  app.use express.static path.join(__dirname, 'public')

app.configure 'development', ->
  app.use express.errorHandler()

app.get '/', routes.index
app.post( '/showinfo', routes.showinfo);

http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')