
argv          = require('minimist')(process.argv.slice(2))
JSON.minify   = JSON.minify ? require("jsonminify")
fs            = require("fs")
async         = require("async")
sprintf       = require("sprintf")
_             = require("lodash")
log           = require('./logging').getLogger("MAIN")

deviceImpl =
    sftp: require('./devices/sftp-device')

config = JSON.parse(JSON.minify(fs.readFileSync(argv["conf"] ? "config.json", 'utf8')))


devices = {}

_.forEach config.devices, (config, name) ->
    if not deviceImpl[config.type]?
        log.error (device: config), "no implementation for device type '#{config.type}'"
    devices[name] = new deviceImpl[config.type](config, name)

_.forEach devices, (dev) ->
    dev.connect()
