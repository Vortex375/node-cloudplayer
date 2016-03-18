
EventEmitter = require('events').EventEmitter
taglib       = require('taglib')
async        = require('async')
_            = require('lodash')

PARALLEL_LIMIT = 3

class Indexer extends EventEmitter

    constructor: ->
        @queue = async.queue ((file, cb) => @readTag(file, cb)), PARALLEL_LIMIT
        @queue.drain = =>
            @emit 'done'

    pushFile: (file) ->
        @queue.push(file)

    readTag: (file, cb) ->
        taglib.tag file, (err, tag) =>
            @emit "tag", file, tag
            return cb(err, tag)


module.exports = Indexer
