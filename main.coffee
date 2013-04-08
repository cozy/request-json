request = require "request"
fs = require "fs"

parseBody =  (error, response, body, callback) ->
    try
        body = JSON.parse(body) if typeof body is "string"
        callback error, response, body
    catch err
        callback err, response, body

# Small HTTP client for easy json interactions with Cozy backends.
class exports.JsonClient


    constructor: (@host) ->


    # Set basic authentication on each requests
    setBasicAuth: (username, password) ->
        credentials = "#{username}:#{password}"
        basicCredentials = new Buffer(credentials).toString('base64')
        @auth = "Basic #{basicCredentials}"

    setToken: (token) ->
        @token = token


    # Send a GET request to path. Parse response body to obtain a JS object.
    get: (path, callback) ->
        request
            method: 'GET'
            headers:
                accept: 'application/json'
                authorization: @auth
                'x-auth-token': @token
            uri: @host + path
            , (error, response, body) ->
                parseBody error, response, body, callback


    # Send a POST request to path with given JSON as body.
    post: (path, json, callback) ->
        request
            method: "POST"
            uri: @host + path
            json: json
            headers:
                authorization: @auth
                'x-auth-token': @token
            , (error, response, body) ->
                parseBody error, response, body, callback


    # Send a PUT request to path with given JSON as body.
    put: (path, json, callback) ->
        request
            method: "PUT"
            uri: @host + path
            json: json
            headers:
                authorization: @auth
                'x-auth-token': @token
            , (error, response, body) ->
                parseBody error, response, body, callback


    # Send a DELETE request to path.
    del: (path, callback) ->
        request
            method: "DELETE"
            uri: @host + path
            headers:
                authorization: @auth
                'x-auth-token': @token
            , (error, response, body) ->
                parseBody error, response, body, callback


    # Send a post request with file located at given path as attachment
    # (multipart form)
    # Use a read stream for that.
    sendFile: (path, filePath, data, callback) ->
        callback = data if typeof(data) is "function"

        req = @post path, null, callback
        form = req.form()
        unless typeof(data) is "function"
            for att of data
                form.append att, data[att]
        form.append 'file', fs.createReadStream(filePath)


    # Retrieve file located at *path* and save it as *filePath*.
    # Use a write stream for that.
    saveFile: (path, filePath, callback) ->
        stream = @get path, callback
        stream.pipe fs.createWriteStream(filePath)
