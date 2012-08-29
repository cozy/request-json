request = require('request')

# Small HTTP client for easy json interactions with Cozy backends.
class exports.JsonClient

    constructor: (@host) ->

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
                

    post: (path, json, callback) ->
        request
            method: "POST"
            uri: @host + path
            json: json
            , callback

    put: (path, json, callback) ->
        request
            method: "PUT"
            uri: @host + path
            json: json
            , callback

    del: (path, callback) ->
        request
            method: "DELETE"
            uri: @host + path
            , callback

