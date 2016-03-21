
EventEmitter = require('events').EventEmitter
MongoClient = require('mongodb').MongoClient;
async        = require('async')
_            = require('lodash')

PARALLEL_LIMIT = 3

class Database extends EventEmitter

    constructor: ->
        @ready = false

    configure: (@url, cb) ->
        MongoClient.connect @url, (err, db) =>
            if err?
                return cb?(err)
            @db = db
            @ready = true
            @emit 'ready'
            cb?()


    shutdown: (cb) ->
        if @db?
            @db.close (err, result) ->
                @db = null
                cb?(err, result)
        else
            process.nextTick -> cb?()
        @ready = false

    collection: (name, cb) ->
        if not @ready
            @once 'ready', => @collection name, cb
            return
        @db.collection name, cb



module.exports = Database
