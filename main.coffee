FormData = require "form-data"
fs = require "fs"
url = require "url"
http = require 'http'


# Create a new object from the first one.
clone = (obj) ->
    result = {}
    result[key] = obj[key] for key of obj
    result


# Merge two objects in one. Values from the second object win over the first
# one.
merge = (obj1, obj2) ->
    result = clone(obj1)
    if obj2?
        result[key] = obj2[key] for key of obj2
    result



# Build parameters required by http lib from options set on the client
# and extra options given for the request.
buildOptions = (clientOptions, clientHeaders, host, path, requestOptions) ->

    # Check if there is something to merge before performing additional
    # operation
    if requestOptions isnt {}
        options = merge clientOptions, requestOptions

    # Check if there are headers to merge before performing additional
    # operation on headers
    if requestOptions? and requestOptions isnt {} and requestOptions.headers
        options.headers = merge clientHeaders, requestOptions.headers

    # If no additional headers are given, it uses the client headers directly.
    else
        options.headers = clientHeaders

    # Buuld host parameters from given URL.
    path = "/#{path}" if path[0] isnt '/'
    urlData = url.parse host
    options.host = urlData.host.split(':')[0]
    options.port = urlData.port
    options.path = path

    options


# Parse body assuming the body is a json object. Send an error if the body
# can't be parsed.
parseBody =  (error, response, body, callback) ->
    if typeof body is "string" and body isnt ""
        try
            parsed = JSON.parse body
        catch err
            error ?= new Error("Parsing error : #{err.message}, body= \n #{body}")
            parsed = body

    else parsed = body

    callback error, response, parsed


# Generic command to play a simple request (withou streaming or form).
playRequest = (opts, data, callback) ->
    req = http.request opts, (res) ->
        res.setEncoding 'utf8'

        body = ''
        res.on 'data', (chunk) -> body += chunk
        res.on 'end', ->
            parseBody null, res, body, callback

    req.on 'error', (err) ->
        callback err

    req.write JSON.stringify data if data?
    req.end()


# Function to make request json more modular.
module.exports =


    newClient: (url, options = {}) ->
        new exports.JsonClient url, options


    get: (opts, data, callback) ->
        opts.method = "GET"
        playRequest opts, data, callback


    del: (opts, data, callback) ->
        opts.method = "DELETE"
        playRequest opts, data, callback


    post: (opts, data, callback) ->
        opts.method = "POST"
        playRequest opts, data, callback


    put: (opts, data, callback) ->
        opts.method = "PUT"
        playRequest opts, data, callback


    patch: (opts, data, callback) ->
        opts.method = "PATCH"
        playRequest opts, data, callback


# Small HTTP client for easy json interactions with Cozy backends.
class exports.JsonClient


    # Set default headers
    constructor: (@host, @options = {}) ->
        @headers = @options.headers ? {}
        @headers['accept'] = 'application/json'
        @headers['user-agent'] = "request-json/1.0"


    # Set basic authentication on each requests
    setBasicAuth: (username, password) ->
        credentials = "#{username}:#{password}"
        basicCredentials = new Buffer(credentials).toString('base64')
        @headers["authorization"] = "Basic #{basicCredentials}"


    # Add a token to request header.
    setToken: (token) ->
        @headers["x-auth-token"] = token


    # Send a GET request to path. Parse response body to obtain a JS object.
    get: (path, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}

        opts = buildOptions @options, @headers, @host, path, options
        module.exports.get opts, null, callback


    # Send a POST request to path with given JSON as body.
    post: (path, data, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}

        opts = buildOptions @options, @headers, @host, path, options
        module.exports.post opts, data, callback


    # Send a PUT request to path with given JSON as body.
    put: (path, data, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}

        opts = buildOptions @options, @headers, @host, path, options
        module.exports.put opts, data, callback


    # Send a PATCH request to path with given JSON as body.
    patch: (path, data, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}

        opts = buildOptions @options, @headers, @host, path, options
        module.exports.patch opts, data, callback


    # Send a DELETE request to path.
    del: (path, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}

        opts = buildOptions @options, @headers, @host, path, options
        module.exports.del opts, null, callback


    # Send a post request with file located at given path as attachment
    # (multipart form)
    sendFile: (path, files, data, callback, parse=true) ->
        callback = data if typeof(data) is "function"

        form = new FormData()

        # Append fields to form.
        unless typeof(data) is "function"
            for att of data
                form.append att, data[att]

        # files is a string so it is a file path
        if typeof files is "string"
            form.append "file", fs.createReadStream files

        # files is not a string and is not an array so it is a stream
        else if not Array.isArray files
            form.append "file", files

        # files is an array of strings and streams
        else
            index = 0
            for file in files
                index++
                if typeof file is "string"
                    form.append "file#{index}", fs.createReadStream(file)
                else
                    form.append "file#{index}", file

        form.submit url.resolve(@host, path), (err, res) ->
            res.setEncoding 'utf8'

            body = ''

            res.on 'data', (chunk) ->
                body += chunk

            res.on 'end', ->
                parseBody null, res, body, callback, parse


    # Retrieve file located at *path* and save it as *filePath*.
    # Use a write stream for that.
    saveFile: (path, filePath, callback) ->
        options = {}
        opts = buildOptions @options, @headers, @host, path, options
        opts.option = "GET"

        req = http.request opts, (res) ->
            res.pipe fs.createWriteStream filePath

            res.on 'end', ->
                callback null, res

        req.on 'error', (err)  ->
            callback err

        req.end()


    # Retrieve file located at *path* and return it as stream.
    saveFileAsStream: (path, callback) ->
        options = {}
        opts = buildOptions @options, @headers, @host, path, options
        opts.option = "GET"

        req = http.request opts, (res) ->
            callback null, res

        req.on 'error', (err)  ->
            callback err

        req.end()
