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
            body = JSON.parse(body) if body? and body
            callback(body, req) if callback?
            res.end(JSON.stringify json)


describe "Common requests", ->

    describe "client.get", ->

        before ->
            @serverGet = fakeServer msg:"ok", 200, (body, req) ->
                req.method.should.equal "GET"
                req.url.should.equal  "/test-path/"
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
            @serverPost = fakeServer msg:"ok", 201, (body, req) ->
                should.exist body.postData
                req.method.should.equal "POST"
                req.url.should.equal  "/test-path/"
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


    describe "client.put", ->

        before ->
            @serverPut = fakeServer msg:"ok", 200, (body, req) ->
                should.exist body.putData
                req.method.should.equal "PUT"
                req.url.should.equal  "/test-path/123"
            @serverPut.listen 8888
            @client = new Client "http://localhost:8888/"

        after ->
            @serverPut.close()
            

        it "When I send put request to server", (done) ->
            @client.put "test-path/123", putData: "data test", (error, response, body) =>
                @response = response
                done()

        it "Then I get 200 as answer", ->
            @response.statusCode.should.be.equal 200
            

    describe "client.del", ->

        before ->
            @serverPut = fakeServer msg:"ok", 204, (body, req) ->
                req.method.should.equal "DELETE"
                req.url.should.equal  "/test-path/123"
            @serverPut.listen 8888
            @client = new Client "http://localhost:8888/"

        after ->
            @serverPut.close()
            
        it "When I send delete request to server", (done) ->
            @client.del "test-path/123", (error, response, body) =>
                @response = response
                done()

        it "Then I get 204 as answer", ->
            @response.statusCode.should.be.equal 204


describe "Basic authentication", ->

    describe "authentified client.get", ->

        before ->
            @serverGet = fakeServer msg:"ok", 200, (body, req) ->
                auth = req.headers.authorization.split(' ')[1]
                auth = new Buffer(auth, 'base64').toString('ascii')
                auth.should.equal 'john:secret'
                req.method.should.equal "GET"
                req.url.should.equal  "/test-path/"
            @serverGet.listen 8888
            @client = new Client "http://localhost:8888/"

        after ->
            @serverGet.close()
            
        it "When I send get request to server", (done) ->
            @client.setBasicAuth 'john', 'secret'
            @client.get "test-path/", (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 200
                @body = body
                done()

        it "Then I get msg: ok as answer.", ->
            should.exist @body.msg
            @body.msg.should.equal "ok"


describe "Set token", ->

    describe "authentified client.get", ->

        before ->
            @serverGet = fakeServer msg:"ok", 200, (body, req) ->
                token = req.headers['x-auth-token']
                token.should.equal 'cozy'
                req.method.should.equal "GET"
                req.url.should.equal  "/test-path/"
            @serverGet.listen 8888
            @client = new Client "http://localhost:8888/"

        after ->
            @serverGet.close()

        it "When I send setToken request", (done) ->
            @client.setToken 'cozy'
            @client.get "test-path/", (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 200
                @body = body
                done()

        it "Then I get msg: ok as answer.", ->
            should.exist @body.msg
            @body.msg.should.equal "ok"

    describe "authentified client.post", ->

        before ->
            @serverPost = fakeServer msg:"ok", 200, (body, req) ->
                token = req.headers['x-auth-token']
                token.should.equal 'cozy'
                should.exist body.postData
                req.method.should.equal "POST"
                req.url.should.equal  "/test-path/"
            @serverPost.listen 8888
            @client = new Client "http://localhost:8888/"

        after ->
            @serverPost.close()

        it "When I send setToken request", (done) ->
            @client.setToken 'cozy'
            @client.post "test-path/", postData:"data test", (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 200
                @body = body
                done()

        it "Then I get msg: ok as answer.", ->
            should.exist @body.msg
            @body.msg.should.equal "ok"