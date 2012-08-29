request = require('request')

# Small HTTP client for easy json interactions with Cozy backends.
class exports.JsonClient

    constructor: (@host) ->

    # Send a GET request to path. Parse response body to obtain a JS object.
    get: (path, callback) ->
        request
            method: "GET"
            headers:
                'accept': 'application/json'
            uri: @host + path
            , (error, response, body) ->
                try
                    body = JSON.parse(body) if typeof body == "string"
                    callback(error, response, body)
                catch err
                    callback(error, response, body)
                

    # Send a POST request to path with given JSON as body.
    post: (path, json, callback) ->
        request
            method: "POST"
            uri: @host + path
            json: json
            , callback


    # Send a PUT request to path with given JSON as body.
    put: (path, json, callback) ->
        request
            method: "PUT"
            uri: @host + path
            json: json
            , callback


    # Send a DELETE request to path.
    del: (path, callback) ->
        request
            method: "DELETE"
            uri: @host + path
            , callback

