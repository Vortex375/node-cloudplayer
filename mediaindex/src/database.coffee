
EventEmitter = require('events').EventEmitter
MongoClient = require('mongodb').MongoClient;
async        = require('async')
_            = require('lodash')

PARALLEL_LIMIT = 3

class Database extends EventEmitter

    constructor: (@url, @targetColl) ->
        @queue = async.queue ((tag, cb) => @saveTag(tag, cb)), PARALLEL_LIMIT
        @queue.drain = =>
            @emit 'done'

    open: (cb) ->
        MongoClient.connect @url, (err, db) =>
            if err?
                return cb(err)
            @db = db
            @db.collection @targetColl, (err, coll) =>
                if err?
                    return cb(err)
                @coll = coll
                cb()

    close: (cb) ->
        if @db?
            @db.close (err, result) ->
                @db = null
                cb?(err, result)
        else
            process.nextTick -> cb?()

    pushTag: (tag, cb) ->
        @queue.push(tag, cb)

    saveTag: (info, cb) ->
        doc = _.assign {}, info.tag
        doc.device = @deviceName
        doc.path = info.file
        doc.lmod = info.stats.mtime
        doc.size = info.stats.size
        @coll.update (path: doc.path), doc, (w: 1, upsert: true), (err, result) =>
            if err?
                @emit "error", err, info
                return cb(err, info)
            cb(null, result)



module.exports = Database
