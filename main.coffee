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
            , (error, response, data) ->
                data = JSON.parse(data) if typeof data == "string"
                callback(error, response, data)

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

    delete: (path, callback) ->
        request
            method: "DELETE"
            uri: @host + path
            , callback

