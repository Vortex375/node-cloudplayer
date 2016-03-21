
log           = require('./logging').getLogger("Devices")
_             = require("lodash")

DEVICE_IMPL =
    sftp: require('./devices/sftp-device')

class Devices

    constructor: ->
        @devices = {}

    configure: (@config) ->

        _.forEach @config, (config, name) =>
            if not DEVICE_IMPL[config.type]?
                log.error (device: config), "no implementation for device type '#{config.type}'"
            @devices[name] = new DEVICE_IMPL[config.type](config, name)

        _.forEach @devices, (dev) ->
            dev.connect()

    get: (dev) ->
        return @devices[dev]

module.exports = new Devices()
