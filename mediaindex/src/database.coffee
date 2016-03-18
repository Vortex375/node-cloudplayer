
EventEmitter = require('events').EventEmitter
MongoClient = require('mongodb').MongoClient;
async        = require('async')
_            = require('lodash')

PARALLEL_LIMIT = 3

class Database extends EventEmitter

    constructor: (@url, @deviceName) ->
        @queue = async.queue ((tag, cb) => @saveTag(tag, cb)), PARALLEL_LIMIT
        @queue.drain = =>
            @emit 'done'

    open: (cb) ->
        MongoClient.connect @url, (err, db) =>
            if err?
                return cb(err)
            @db = db
            @db.collection 'tracks', (err, coll) =>
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

    saveTag: (tag, cb) ->
        tag.tag.path = tag.file
        tag.tag.device = @deviceName
        @coll.update (path: tag.file), tag.tag, (w: 1, upsert: true), (err, result) =>
            if err?
                @emit "error", err, tag
                return cb(err, tag)
            cb(null, result)



module.exports = Database
