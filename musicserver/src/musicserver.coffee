
argv          = require('minimist')(process.argv.slice(2))
JSON.minify   = JSON.minify ? require("jsonminify")
fs            = require("fs")
async         = require("async")
sprintf       = require("sprintf")
_             = require("lodash")
log           = require('./logging').getLogger("MAIN")
express       = require('express')
parseRange    = require('range-parser')

Devices       = require('./devices')


config = JSON.parse(JSON.minify(fs.readFileSync(argv["conf"] ? "config.json", 'utf8')))


devices = new Devices(config.devices)

app = express()

app.get '/', (req, res) ->
    res.write "Hello World!"

app.get '/service/file/:device*?', (req, res) ->
    console.log "params:", req.params
    if req.headers.range?
        console.log "range:", parseRange(req.headers.range)
    device = req.params.device
    if not device?
        return res.status(404).send "Please specify device"
    path = req.params[0]
    if not path? or path == ''
        path = '/'

    dev = devices.get(device)

    stream = dev.createReadStream(path)
    stream.on 'error', (err)->
        log.error err, "Device stream read error"
        res.status(500).end()
    stream.pipe(res)


app.listen(8081)
log.info "HTTP Server listening on :8081"
