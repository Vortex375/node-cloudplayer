
argv        = require('minimist')(process.argv.slice(2))
Spinner     = require('cli-spinner').Spinner
sprintf     = require('sprintf')
DirWalker   = require('./dirwalker')
Indexer     = require('./indexer')

console.log()
console.log("MediaIndex")
console.log()

if argv._.length == 0
    console.log "Usage: mediaindex <input dir>"
    process.exit(1)

walker = new DirWalker(argv._[0])
indexer = new Indexer()

walker.on 'error', (err) ->
    #console.log "error:", err

taggedFiles = 0
numFiles = 0
walker.on 'file', (file) ->
    numFiles++
    indexer.pushFile(file)

indexer.on 'tag', (file, tag) ->
    taggedFiles++

walker.walk()
if not argv["silent"]?
    sp = new Spinner("Scanning: ")
    sp.setSpinnerString(0)
    sp.start()
    setInterval(->
        sp.setSpinnerTitle("Indexing: (#{taggedFiles}/#{numFiles}) files (#{sprintf('%.02d', taggedFiles* 100/numFiles)}%).")
    , 500).unref()
    walker.on 'done', ->
        sp.stop(true)
        console.log("Done: #{numFiles} files found.")
        console.log();
