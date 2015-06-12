mongoose = require('mongoose')
LogHarvester = require('./lib/log-monitor').LogHarvester



logPath = 'test/syslog';
mongoose.connect('mongodb://localhost/bwss-monitor');
monitor = new LogHarvester(logPath);
monitor.run();


