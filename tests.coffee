should = require('chai').Should()
http = require "http"

Client = require("./main").JsonClient


fakeServer = (json, code=200, callback=null) ->
    http.createServer (req, res) ->
        body = ""
        req.on 'data', (chunk) ->
            body += chunk
        req.on 'end', ->
            res.writeHead code, 'Content-Type': 'application/json'
            callback(JSON.parse body) if callback?
            res.end(JSON.stringify json)


describe "Client methods", ->

    describe "client.get", ->

        before ->
            @serverGet = fakeServer msg:"ok"
            @serverGet.listen 8888
            @client = new Client "http://localhost:8888/"

        after ->
            @serverGet.close()
            
        it "When I send get request to server", (done) ->
            @client.get "test-path/", (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 200
                @body = body
                done()

        it "Then I get msg: ok as answer.", ->
            should.exist @body.msg
            @body.msg.should.equal "ok"


    describe "client.post", ->

        before ->
            @serverPost = fakeServer msg:"ok", 201, (body) ->
                should.exist body.postData
            @serverPost.listen 8888
            @client = new Client "http://localhost:8888/"

        after ->
            @serverPost.close()
            

        it "When I send post request to server", (done) ->
            @client.post "test-path/", postData: "data test", (error, response, body) =>
                should.not.exist error
                @response = response
                @body = body
                done()

        it "Then I get 201 as answer", ->
            @response.statusCode.should.be.equal 201
            should.exist @body.msg
            @body.msg.should.equal "ok"
