fs = require 'fs'
mongoose = require 'mongoose'
harvester = require './harvester'
util = require './util'

logPath = './res/mock.log'

mongoose.connect 'mongodb://localhost/bwss-monitor'

coolFarmer = new harvester.Harvester(logPath, true)
lazyPoliceman = new util.FileWatcher(logPath)


# On log path setup, farmer is ready and start to harvest
coolFarmer.on 'ready', -> coolFarmer.harvest()

# When leftover log harvest done, farmer emit 'finish' and policeman start to watch.
# When file change is found, policeman emit 'change' and stops watching.
coolFarmer.on 'finish', -> lazyPoliceman.watch()

# Only when 'change' is received, farmer will start to harvest.
lazyPoliceman.on 'change', -> coolFarmer.harvest()
