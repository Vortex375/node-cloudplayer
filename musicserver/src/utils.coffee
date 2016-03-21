
_ = require('lodash')

module.exports =

    parseSize: (str) ->
        if not str?
            return undefined

        if not str.match(/^[0-9]+[kmgKMG]?$/)?
            throw "invalid size string"

        size = str.match(/^[0-9]+/)[0]
        modifier = str.match(/[kmgKMG]?$/)[0]

        return switch _.lowerCase(modifier)
            when '' then size
            when 'k' then size * 1024
            when 'm' then size * 1024 * 1024
            when 'g' then size * 1024 * 1024 * 1024

    hrtimems: (hrtime) ->
        if not hrtime?
            return undefined
        hrtime[0] * 1e3 + hrtime[1] / 1e6
