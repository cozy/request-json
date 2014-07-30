request = require "request"
fs = require "fs"
url = require "url"
http = require 'http'

clone = (obj) ->
    result = {}
    result[key] = obj[key] for key of obj
    result

merge = (obj1, obj2) ->
    result = clone(obj1)
    if obj2?
        result[key] = obj2[key] for key of obj2
    result


buildOptions = (clientOptions, clientHeaders, host, path, requestOptions) ->
    # Check if there is something to merge before performing additional
    # operation
    if requestOptions isnt {}
        options = merge clientOptions, requestOptions
    if requestOptions? and requestOptions isnt {} and requestOptions.headers
        options.headers = merge clientHeaders, requestOptions.headers
    else
        options.headers = clientHeaders
    options.uri = url.resolve host, path
    options


playReq = (opts, data, callback) ->
    body = ''
    req = http.request opts, (res) ->
        res.setEncoding 'utf8'
        res.on 'data', (chunk) ->
            body += chunk

        res.on 'end', ->
            parseBody null, res, body, callback

    req.on 'error', (err) ->
        callback err

    req.end()


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

# Function to make request json more modular.
exports.newClient = (url, options = {}) -> new exports.JsonClient url, options


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
        opts.method = 'GET'

        request opts, (error, response, body) ->
            if parse then parseBody error, response, body, callback
            else callback error, response, body


    # Send a POST request to path with given JSON as body.
    post: (path, json, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = buildOptions @options, @headers, @host, path, options
        opts.method = "POST"
        opts.json = json

        request opts, (error, response, body) ->
            if parse then parseBody error, response, body, callback
            else callback error, response, body


    # Send a PUT request to path with given JSON as body.
    put: (path, json, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = buildOptions @options, @headers, @host, path, options
        opts.method = "PUT"
        opts.json = json

        request opts, (error, response, body) ->
            if parse then parseBody error, response, body, callback
            else callback error, response, body


    # Send a PATCH request to path with given JSON as body.
    patch: (path, json, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = buildOptions @options, @headers, @host, path, options
        opts.method = "PATCH"
        opts.json = json

        request opts, (error, response, body) ->
            if parse then parseBody error, response, body, callback
            else callback error, response, body


    # Send a DELETE request to path.
    del: (path, callback, parse = true) ->
        urlData = url.parse @host
        @options.host = urlData.host.split(':')[0]
        @options.port = urlData.port

        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = buildOptions @options, @headers, @host, path, options
        opts.method = "DELETE"
        path = "/#{path}" if path[0] isnt '/'
        opts.path = path
        console.log opts

        playRequest opts, null, callback

    # Send a post request with file located at given path as attachment
    # (multipart form)
    # Use a read stream for that.
    # If you use a stream, it must have a "path" attribute...
    # ...with its path or filename
    sendFile: (path, files, data, callback) ->
        callback = data if typeof(data) is "function"
        req = @post path, null, callback, false #do not parse

        form = req.form()
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


    # Retrieve file located at *path* and save it as *filePath*.
    # Use a write stream for that.
    saveFile: (path, filePath, callback) ->
        stream = @get path, callback, false  # do not parse result
        stream.pipe fs.createWriteStream(filePath)


    # Retrieve file located at *path* and return it as stream.
    saveFileAsStream: (path, callback) ->
        @get path, callback, false  # do not parse result
