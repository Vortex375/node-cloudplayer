
argv        = require('minimist')(process.argv.slice(2))
Spinner     = require('cli-spinner').Spinner
sprintf     = require('sprintf')
async       = require('async')

DirWalker   = require('./dirwalker')
Indexer     = require('./indexer')
Database    = require('./database')

PARALLEL_LIMIT = 3

console.log()
console.log("MediaIndex")
console.log()

if argv._.length != 3
    console.log "Usage: mediaindex <db url> <target-coll> <input dir>"
    process.exit(1)

walker  = new DirWalker(argv._[2])
indexer = new Indexer()
db      = new Database(argv._[0], argv._[1])

taggedFiles = 0
numFiles = 0

walker.on 'error', (err) ->
    #console.log "error:", err
db.on 'error', (err, tag) ->
    console.warn("Failed to save tag for:", tag.file)

queue = async.queue (file, cb) ->
    async.waterfall [
        (cb) -> indexer.readTag(file, cb)
        (tag, stats, cb) -> db.saveTag (file: file, stats: stats, tag: tag), cb
    ], (err) ->
        # ignore errors here
        taggedFiles++
        cb()
, PARALLEL_LIMIT

walker.on 'file', (file) ->
    numFiles++
    queue.push file

console.log "connecting to database..."
db.open (err) ->
    if (err?)
        console.log "connection failed:", err
        process.exit(1)

    console.log "success."
    console.log()

    walker.walk()
    sp = new Spinner("Scanning: ")
    sp.setSpinnerString(0)
    sp.start()
    setInterval(->
        return if numFiles == 0
        sp.setSpinnerTitle("Indexing: (#{taggedFiles}/#{numFiles}) files (#{sprintf('%.02d', taggedFiles* 100/numFiles)}%).")
    , 500).unref()
    walker.on 'done', -> queue.drain = ->
        sp.stop(true)
        console.log("Done: #{taggedFiles} files indexed.")
        console.log();
        console.log "closing database..."
        db.close ->
            console.log "done."
