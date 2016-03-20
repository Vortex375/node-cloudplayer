
EventEmitter = require('events').EventEmitter
fs           = require('fs')
path         = require('path')
async        = require('async')
_            = require('lodash')

PARALLEL_LIMIT = 3

class DirWalker extends EventEmitter

    constructor: (@path) ->
        @queue = async.queue ((dir, cb) => @walkPath(dir, cb)), PARALLEL_LIMIT
        @queue.drain = =>
            @emit 'done'

    walk: ->
        @walkPath(@path)

    walkPath: (dirPath, cb) ->
        fs.readdir dirPath, (err, files) =>
            if err?
                @emit 'error', err
                return cb()
            async.eachLimit files, PARALLEL_LIMIT, (f, cb) =>
                file = path.resolve(dirPath, f)
                fs.stat file, (err, stats) =>
                    if err?
                        @emit 'error', err
                        return cb()
                    if stats.isDirectory()
                        @queue.push file
                    else if stats.isFile()
                        @emit 'file', file, stats
                    return cb()
            , cb


module.exports = DirWalker
