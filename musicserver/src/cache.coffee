log           = require('./logging').getLogger("Cache")
_             = require('lodash')
async         = require('async')
fs            = require('fs')
path          = require('path')
stream        = require('stream')
EventEmitter  = require('events').EventEmitter

db            = require('./database')

class Cache extends EventEmitter

    constructor: ->

    configure: (@config) ->
        @ready = false

        if not @config.dir?
            throw "Missing cache.dir in config"
        if not @config.maxSize?
            log.warn "cache.maxSize not set - defaulting to 5G"
            @config.maxSize = 5368709120

        async.series [
            (cb) => db.collection 'cache', (err, coll) =>
                @coll = coll
                cb(err)
            (cb) => db.collection 'tracks', (err, coll) =>
                @tracks = coll
                cb(err)
        ], (err) =>
            if err?
                log.fatal err, "Unable to get database collections"
                @emit 'error', err
                return

            @indexCache()

    indexCache: ->
        cacheIndexStart = process.hrtime()

        dir = path.resolve(@config.dir)
        fs.readdir dir, (err, files) =>
            if err?
                log.fatal err, "Unable to access cache directory"
                @emit 'error', err
                return

            validFileNames = []
            async.series(
                [

                    (cb) => async.eachSeries(
                        files
                        (file, cb) =>
                            cargo = {}
                            async.waterfall(
                                [
                                    (cb) =>
                                        fs.stat path.resolve(dir, file), cb
                                    (stats, cb) =>
                                        cargo.stats = stats
                                        if not stats.isFile()
                                            log.warn "non-file item in cache directory: '#{file}'"
                                            return cb('skip')
                                        try
                                            cargo.id = parseInt(file)
                                            validFileNames.append(cargo.id)
                                        catch err
                                            log.warn "item in cache directory has invalid name (non-integer): '#{file}'"
                                            return cb('skip')
                                        @coll.find (_id: cargo.id), cb
                                    (cursor, cb) =>
                                        cursor.next cb
                                    (item, cb) =>
                                        if not item?
                                            log.info "adding previously unindexed file to cache: '#{file}'"
                                            return @addToIndex cargo.id, stats, cb
                                        if item.available != stats.size
                                            log.warn "size mismatch: file size does not match db. removing file from cache dir: '#{file}'"
                                            fs.unlink path.resolve(dir, file), cb
                                        else
                                            log.info "file '#{file}' indexed ok."
                                ]
                                (err) ->
                                    # do not pass errors to eachSeries()
                                    return cb()
                            ) # end waterfall()
                        cb
                    ) #end eachSeries()

                    (cb) =>
                        cargo = {}
                        async.waterfall(
                            [
                                (cb) =>
                                    @coll.find (_id: ($nin: validFileNames)), cb
                                (cursor, cb) =>
                                    cargo.cursor = cursor
                                    cursor.next cb
                                (item, cb) =>
                                    async.whilst(
                                        -> item?
                                        (cb) =>
                                            async.waterfall(
                                                [
                                                    (cb) =>
                                                        log.warn "cache item in db is missing file: #{item._id}"
                                                        @coll.deleteOne (_id: item._id), (w:1), cb
                                                    (result, cb) =>
                                                        cargo.cursor.next cb
                                                    (i, cb) ->
                                                        item = i
                                                        cb()
                                                ]
                                                cb
                                            ) # end waterfall()
                                        cb
                                    ) # end whilst()
                            ]
                            cb
                        ) # end waterfall()
                ]
                (err) =>
                    if err?
                        log.fatal err, "error while indexing cache"
                        @emit "error", err
                        return
                    t = utils.hrtimems(process.hrtime(cacheIndexStart))
                    log.info (t: t), "cache index complete (#{t} ms)"
                    @ready = true
                    @emit "ready"
            ) # end series()

    addToIndex: (id, stats, cb) ->
        file = path.resolve(@config.dir, '' + id)
        async.waterfall [
            (cb) =>
                @tracks.find (_id: id), cb
            (track, cb) =>
                if not track?
                    log.warn "file in cache directory not recognized: '#{id}'"

                cacheEntry =
                    id : _id
                    available: stats.size
                    size: track.size

                @coll.insertOne cacheEntry, (w: 1), cb
        ]
