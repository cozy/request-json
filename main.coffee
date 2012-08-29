request = require('request')

# Small HTTP client for easy json interactions with Cozy backends.
class exports.Client

    constructor: (@host) ->

    get: (path, callback) ->
        request
            method: "GET"
            uri: @host + path
            , callback

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

