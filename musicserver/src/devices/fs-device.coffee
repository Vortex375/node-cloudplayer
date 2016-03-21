
EventEmitter = require('events').EventEmitter
async        = require('async')
_            = require('lodash')
logging      = require('../logging')

fs           = require('fs')

class FsDevice extends EventEmitter

    constructor: (@config, @name) ->
        @ready = true
        @log = logging.getLogger("FsDevice", @name)

    connect: ->

    createReadStream: (path) ->
        return fs.createReadStream path


module.exports = FsDevice
