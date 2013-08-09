request = require "request"
fs = require "fs"
url = require "url"

parseBody =  (error, response, body, callback) ->
    if typeof body is "string" and body isnt ""
        try
            parsed = JSON.parse(body)
        catch err
            error ?= err
            parsed = body

    else parsed = body

    callback error, response, parsed


# Small HTTP client for easy json interactions with Cozy backends.
class exports.JsonClient

    agent: "request-json/1.0"

    constructor: (@host) ->


    # Set basic authentication on each requests
    setBasicAuth: (username, password) ->
        credentials = "#{username}:#{password}"
        basicCredentials = new Buffer(credentials).toString('base64')
        @auth = "Basic #{basicCredentials}"

    setToken: (token) ->
        @token = token


    # Send a GET request to path. Parse response body to obtain a JS object.
    get: (path, callback, parse = true) ->
        request
            method: 'GET'
            headers:
                accept: 'application/json'
                authorization: @auth
                "user-agent": @agent
                'x-auth-token': @token
            uri: url.resolve(@host, path)
            , (error, response, body) ->
                if parse then parseBody error, response, body, callback
                else callback error, response, body


    # Send a POST request to path with given JSON as body.
    post: (path, json, callback, parse = true) ->
        request
            method: "POST"
            uri: url.resolve(@host, path)
            json: json
            headers:
                authorization: @auth
                "user-agent": @agent
                'x-auth-token': @token
            , (error, response, body) ->
                if parse then parseBody error, response, body, callback
                else callback error, response, body


    # Send a PUT request to path with given JSON as body.
    put: (path, json, callback) ->
        request
            method: "PUT"
            uri: url.resolve(@host, path)
            json: json
            headers:
                authorization: @auth
                "user-agent": @agent
                'x-auth-token': @token
            , (error, response, body) ->
                parseBody error, response, body, callback


    # Send a DELETE request to path.
    del: (path, callback) ->
        request
            method: "DELETE"
            uri: url.resolve(@host, path)
            headers:
                authorization: @auth
                'x-auth-token': @token
            , (error, response, body) ->
                parseBody error, response, body, callback


    # Send a post request with file located at given path as attachment
    # (multipart form)
    # Use a read stream for that.
    sendFile: (path, files, data, callback) ->
        callback = data if typeof(data) is "function"
        req = @post path, null, callback, false #do not parse
        form = req.form()
        unless typeof(data) is "function"
            for att of data
                form.append att, data[att]
        # files is a string so it is a file path
        if typeof files is "string"
            form.append "file", fs.createReadStream(files)
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
        stream = @get path, callback, false #do not parse
        stream.pipe fs.createWriteStream(filePath)
