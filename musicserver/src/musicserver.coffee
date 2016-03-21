
argv          = require('minimist')(process.argv.slice(2))
JSON.minify   = JSON.minify ? require("jsonminify")
fs            = require("fs")
async         = require("async")
sprintf       = require("sprintf")
_             = require("lodash")
log           = require('./logging').getLogger("MAIN")

devices       = require('./devices')
server        = require('./http-server')


config = JSON.parse(JSON.minify(fs.readFileSync(argv["conf"] ? "config.json", 'utf8')))

cache.configure config.cache
devices.configure config.devices
server.configure config.port ? 8081
