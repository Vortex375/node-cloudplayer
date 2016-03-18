
EventEmitter = require('events').EventEmitter
async        = require('async')
_            = require('lodash')
logging      = require('../logging')

Client = require('ssh2').Client;

class SftpDevice extends EventEmitter

    constructor: (@config, @name) ->
        @conn = new Client()
        @ready = false
        @log = logging.getLogger("SftpDevice", @name)

        @conn.on 'error', (err) =>
            @log.error err, "Connection Error"
            @emit 'error', err

        @conn.on 'end', =>
            @log.warn "connection closed"

    connect: ->
        @conn.once 'ready', =>
            @log.info "opening sftp session..."
            @conn.sftp (err, sftp) =>
                if err?
                    @log.error err, "error opening sftp session"
                    return @emit "error", err
                @sftp = sftp
                @ready = true
                @log.info "connected"
                @emit "ready"

        @log.info "connecting..."
        @conn.connect
            host: @config['sftp-host']
            port: @config['sftp-port']
            username: @config['sftp-username']
            password: @config['sftp-password']
            #debug: console.log


module.exports = SftpDevice
