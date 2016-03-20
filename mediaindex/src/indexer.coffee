
EventEmitter = require('events').EventEmitter
taglib       = require('taglib')
async        = require('async')
_            = require('lodash')

PARALLEL_LIMIT = 3

class Indexer extends EventEmitter

    constructor: ->
        @queue = async.queue ((file, stats, cb) => @readTag(file, stats, cb)), PARALLEL_LIMIT
        @queue.drain = =>
            @emit 'done'

    pushFile: (file, stats, cb) ->
        @queue.push(file, stats, cb)

    readTag: (file, stats, cb) ->
        taglib.tag file, (err, tag) =>
            @emit "tag", file, tag, stats
            return cb(err, tag, stats)


module.exports = Indexer
