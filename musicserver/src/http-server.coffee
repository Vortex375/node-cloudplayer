log           = require('./logging').getLogger("Http")
express       = require('express')
parseRange    = require('range-parser')

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

    stream = cache.getStream device, path

    dev = devices.get(device)

    stream = dev.createReadStream(path)
    stream.on 'error', (err) ->
        log.error err, "Device stream read error"
        res.status(500).end()
    stream.pipe(res)


class HttpServer

    constructor: ->

    configure (@port) ->
        app.listen(@port)
        log.info "HTTP Server listening on :#{@port}"
