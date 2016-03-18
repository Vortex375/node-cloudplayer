argv          = require('minimist')(process.argv.slice(2))
JSON.minify   = JSON.minify ? require("jsonminify")
fs            = require("fs")
async         = require("async")
sprintf       = require("sprintf")
MongoClient   = require("mongodb").MongoClient
Spinner       = require('cli-spinner').Spinner

config = JSON.parse(JSON.minify(fs.readFileSync(argv["conf"] ? "config.json", 'utf8')))

if argv._.length != 2
    console.log "Usage: index-import <device> <source collection>"
    process.exit(1)

device = argv._[0]
sourceColl = argv._[1]

console.log "connecting to database..."
MongoClient.connect config["db"], (err, db) ->
    if err?
        console.log "connection failed:", err
        return

    cargo =
        sColl: null
        tColl: null
        cursor: null
        count: 0
        processed: 0

    console.log()
    sp = new Spinner("Importing: reading database")
    sp.start()
    async.waterfall [
        (cb) ->
            db.collection sourceColl, (strict:true), cb
        (coll, cb) ->
            cargo.sColl = coll
            db.collection 'tracks', cb
        (coll, cb) ->
            cargo.tColl = coll

            coll.deleteMany (device: device), (w: 1), cb
        (deleted, cb) ->
            console.log()
            console.log "dropped #{deleted.result.n} existing entries for device #{device}"
            cargo.cursor = cursor = cargo.sColl.find()
            cursor.count cb
        (count, cb) ->
            cargo.count = count
            sp.setSpinnerTitle "Importing: (0/#{cargo.count}) tracks (0%)"

            cargo.cursor.next cb
        (track, cb) ->
            async.whilst(
                -> track?
                (cb) ->
                    track.device = device
                    async.waterfall [
                        (cb) ->
                            cargo.tColl.insertOne track, (w: 1), cb
                        (result, cb) ->
                            cargo.processed++
                            sp.setSpinnerTitle "Importing: (#{cargo.processed}/#{cargo.count}) tracks (#{sprintf('%.02d', cargo.processed* 100/cargo.count)}%)"
                            cargo.cursor.next cb
                        (t, cb) ->
                            track = t
                            cb()
                    ], cb
                cb
            )
    ], (err) ->
        sp.stop(true)
        if err?
            console.log "error:", err
            db.close()
            return

        sp.stop(true)
        console.log "Done: #{cargo.processed} tracks imported."
        console.log()
        db.close()
