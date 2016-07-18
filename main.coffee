request = require "request"
fs = require "fs"
url = require "url"
depd = require "depd"
deprecate = depd "request-json"


requestJson = module.exports

# Function to build a request json client instance.
requestJson.createClient = (url, options = {}) ->
    new requestJson.JsonClient url, options


requestJson.newClient = (url, options = {}) ->
    deprecate "newClient() is deprecated, please use createClient()"
    requestJson.createClient(url, options)


helpers =

    # Merge two js objects. The result is a new object, the ones given in
    # parameter are not changed.
    merge: (obj1, obj2) ->
        result = {}
        result[key] = obj1[key] for key of obj1
        if obj2?
            result[key] = obj2[key] for key of obj2
        result

    # Build request options from every given parameters.
    buildOptions: (clientOptions, clientHeaders, host, path, requestOptions) ->
        # Check if there is something to merge before performing additional
        # operation
        if requestOptions isnt {}
            options = helpers.merge clientOptions, requestOptions
        if requestOptions? and requestOptions isnt {} and requestOptions.headers
            options.headers = \
                helpers.merge clientHeaders, requestOptions.headers
        else
            options.headers = clientHeaders
        options.uri = url.resolve host, path
        options

    # Parse body assuming the body is a json object. Send an error if the body
    # can't be parsed.
    parseBody: (error, response, body, callback) ->
        if typeof body is "string" and body isnt ""
            try
                parsed = JSON.parse body
            catch err
                msg = "Parsing error : #{err.message}, body= \n #{body}"
                error ?= new Error msg
                parsed = body

        else parsed = body

        callback error, response, parsed


# Small HTTP client for easy json interactions with Cozy backends.
class requestJson.JsonClient


    # Set default headers
    constructor: (@host, @options = {}) ->
        @headers = @options.headers ? {}
        @headers['accept'] = 'application/json'
        @headers['user-agent'] = "request-json/1.0"


    # Set basic authentication on each requests
    setBasicAuth: (username, password) ->
        @options.auth =
            user: username
            pass: password

    # Set digest auth
    setDigestAuth: (username, password) ->
        @options.auth =
            user: username
            pass: password
            sendImmediately: false

    # Add a token to request header.
    setToken: (token) ->
        @headers["x-auth-token"] = token

    # Add OAuth2 Bearer token to request header.
    setBearerToken: (token) ->
        @options.auth = bearer: token

    # Send a GET request to path. Parse response body to obtain a JS object.
    get: (path, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = helpers.buildOptions @options, @headers, @host, path, options
        opts.method = 'GET'

        request opts, (error, response, body) ->
            if parse then helpers.parseBody error, response, body, callback
            else callback error, response, body


    # Send a POST request to path with given JSON as body.
    post: (path, json, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = helpers.buildOptions @options, @headers, @host, path, options
        opts.method = "POST"
        opts.json = json

        request opts, (error, response, body) ->
            if parse then helpers.parseBody error, response, body, callback
            else callback error, response, body


    # Send a PUT request to path with given JSON as body.
    put: (path, json, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = helpers.buildOptions @options, @headers, @host, path, options
        opts.method = "PUT"
        opts.json = json

        request opts, (error, response, body) ->
            if parse then helpers.parseBody error, response, body, callback
            else callback error, response, body


    # Send a PATCH request to path with given JSON as body.
    patch: (path, json, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = helpers.buildOptions @options, @headers, @host, path, options
        opts.method = "PATCH"
        opts.json = json

        request opts, (error, response, body) ->
            if parse then helpers.parseBody error, response, body, callback
            else callback error, response, body


    # Send a HEAD request to path. Expect no response body.
    head: (path, options, callback) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = helpers.buildOptions @options, @headers, @host, path, options
        opts.method = 'HEAD'

        request opts, (error, response, body) ->
            callback error, response


    # Send a DELETE request to path.
    del: (path, options, callback, parse = true) ->
        if typeof options is 'function'
            parse = callback if typeof callback is 'boolean'
            callback = options
            options = {}
        opts = helpers.buildOptions @options, @headers, @host, path, options
        opts.method = "DELETE"

        request opts, (error, response, body) ->
            if parse then helpers.parseBody error, response, body, callback
            else callback error, response, body


    # Alias for del
    delete: (path, options, callback, parse = true) ->
        @del path, options, callback, parse


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


    # Send a put request with file located at given path as attachment.
    # Use a read stream for that.
    # If you use a stream, it must have a "path" attribute...
    # ...with its path or filename
    putFile: (path, file, data, callback) ->
        callback = data if typeof(data) is "function"
        req = @put path, null, callback, false #do not parse

        # file is a string so it is a file path
        if typeof file is "string"
            fs.createReadStream(file).pipe(req)

        # file is not a string and is not an array so it is a stream
        else if not Array.isArray file
            file.pipe(req)


    # Retrieve file located at *path* and save it as *filePath*.
    # Use a write stream for that.
    saveFile: (path, filePath, callback) ->
        stream = @get path, callback, false  # do not parse result
        stream.pipe fs.createWriteStream(filePath)


    # Retrieve file located at *path* and return it as stream.
    saveFileAsStream: (path, callback) ->
        @get path, callback, false  # do not parse result

    # Promised version of get
    getAsync: (path, parse) ->
        Promise = @getPromise()

        return new Promise((resolve, reject) =>
            @get(path, (err, res, body) ->
                if (err)
                    return reject(err)
                resolve([res, body])
            , parse)
        )

    # Promised version of post
    postAsync: (path, json, parse) ->
        Promise = @getPromise()

        return new Promise((resolve, reject) =>
            @post(path, json, (err, res, body) ->
                if (err)
                    return reject(err)
                resolve([res, body])
            , parse)
        )

    # Promised version of put
    putAsync: (path, json, parse) ->
        Promise = @getPromise()

        return new Promise((resolve, reject) =>
            @put(path, json, (err, res, body) ->
                if (err)
                    return reject(err)
                resolve([res, body])
            , parse)
        )

    # Promised version of patch
    patchAsync: (path, json, parse) ->
        Promise = @getPromise()

        return new Promise((resolve, reject) =>
            @patch(path, json, (err, res, body) ->
                if (err)
                    return reject(err)
                resolve([res, body])
            , parse)
        )

    # Promised version of del
    delAsync: (path, parse) ->
        Promise = @getPromise()

        return new Promise((resolve, reject) =>
            @del(path, (err, res, body) ->
                if (err)
                    return reject(err)
                resolve([res, body])
            , parse)
        )

    # Promised version of head
    headAsync: (path, parse) ->
        Promise = @getPromise()

        return new Promise((resolve, reject) =>
            @head(path, (err, res, body) ->
                if (err)
                    return reject(err)
                resolve([res, body])
            , parse)
        )

    getPromise: () ->
        Promise = @options.Promise || global.Promise
        if (!Promise)
            throw new Error "No Promise provided"

        return Promise
