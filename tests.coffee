should = require('chai').Should()
http = require "http"
express = require "express"
fs = require "fs"
path = require "path"
bodyParser = require 'body-parser'
multiparty = require 'connect-multiparty'
request = require("./main")


fakeServer = (json, code=200, callback=null) ->
    http.createServer (req, res) ->
        body = ""
        res.setHeader 'headertest', 'header-value'
        req.on 'data', (chunk) ->
            body += chunk
        req.on 'end', ->
            res.writeHead code, 'Content-Type': 'application/json'
            body = JSON.parse(body) if body? and body
            callback(body, req) if callback?
            res.end(JSON.stringify json)

fakeServerRaw = (code, out) ->
     http.createServer (req, res) ->
        req.on 'data', (chunk) ->
        req.on 'end', ->
            res.writeHead code
            res.end out

fakeDownloadServer = (url, path, callback= ->) ->
    app = express()
    app.get url, (req, res) ->
        res.sendfile path
        callback req

fakeUploadServer = (url, dir, callback= -> ) ->
    app = express()
    fs.mkdirSync dir unless fs.existsSync dir
    app.use bodyParser()
    app.use multiparty uploadDir: dir
    app.post url, (req, res) ->
        for key, file of req.files
            fs.renameSync file.path, dir + '/' + file.name
        res.send 201

rawBody = (req, res, next) ->
    req.setEncoding 'utf8'
    req.rawBody = ''
    req.on 'data', (chunk) ->
        req.rawBody += chunk
    req.on 'end', () ->
        next()

fakePutServer = (url, dir, callback= -> ) ->
    app = express()
    fs.mkdirSync dir unless fs.existsSync dir
    app.use rawBody
    app.put url, (req, res) ->
        fs.writeFile "#{dir}/file", req.rawBody, (err) ->
            unless err
                res.send 201


describe "Common requests", ->

    describe "client.get", ->

        before ->
            @serverGet = fakeServer msg:"ok", 200, (body, req) ->
                req.method.should.equal "GET"
                req.url.should.equal  "/test-path/"
            @serverGet.listen 8888
            @client = request.createClient "http://localhost:8888/"

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
            @client = request.createClient "http://localhost:8888/"

        after ->
            @serverPost.close()


        it "When I send post request to server", (done) ->
            data = postData: "data test"
            @client.post "test-path/", data, (error, response, body) =>
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
            @client = request.createClient "http://localhost:8888/"

        after ->
            @serverPut.close()


        it "When I send put request to server", (done) ->
            data = putData: "data test"
            @client.put "test-path/123", data, (error, response, body) =>
                @response = response
                done()

        it "Then I get 200 as answer", ->
            @response.statusCode.should.be.equal 200


    describe "client.patch", ->

        before ->
            @serverPatch = fakeServer msg:"ok", 200, (body, req) ->
                should.exist body.patchData
                req.method.should.equal "PATCH"
                req.url.should.equal  "/test-path/123"
            @serverPatch.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            @serverPatch.close()


        it "When I send patch request to server", (done) ->
            data = patchData: "data test"
            @client.patch "test-path/123", data, (error, response, body) =>
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
            @client = request.createClient "http://localhost:8888/"

        after ->
            @serverPut.close()

        it "When I send delete request to server", (done) ->
            @client.del "test-path/123", (error, response, body) =>
                @response = response
                done()

        it "Then I get 204 as answer", ->
            @response.statusCode.should.be.equal 204

    describe "client.put followed by client.del", ->

        before ->
            @client = request.createClient "http://localhost:8888/"
            @serverPut = fakeServer msg:"ok", 204, (body, req) ->
                if req.method is "PUT"
                    should.exist body.putData
                if req.method is "DELETE"
                    should.not.exist body.putData
                req.url.should.equal  "/test-path/123"
            @serverPut.listen 8888

        after ->
            @serverPut.close()

        it "When I send put request to server", (done) ->
            data = putData: "data test"
            @client.put "test-path/123", data, (error, response, body) =>
                @response = response
                done()

        it "And then send delete request to server", (done) ->
            @client.del "test-path/123", (error, response, body) =>
                @response = response
                done()

        it "Then I get 204 as answer", ->
            @response.statusCode.should.be.equal 204

    describe "client.head", ->

        before ->
            @serverHead = fakeServer msg:"ok", 200, (body, req) ->
                req.method.should.equal "HEAD"
                req.url.should.equal "/test-path/124"
            @serverHead.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            @serverHead.close()


        it "When I send head request to server", (done) ->
            data = headData: "head data test"
            @client.head "test-path/124", data, (error, response, body) =>
                @response = response

                done()

        it "Then I get 200 as answer", ->
            @response.statusCode.should.be.equal 200
            @response.body.length.should.equal 0
            @response.headers.headertest.should.equal 'header-value'

describe "Parsing edge cases", ->

    describe "no body on 204", ->

        before ->
            @server = fakeServerRaw 204, ''
            @server.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            @server.close()

        it 'should not throw', (done) ->
            @client.del "test-path/", (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 204
                body.should.equal ''
                done()

    describe "invalid json", ->

        before ->
            @server = fakeServerRaw 200, '{"this:"isnotjson}'
            @server.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            @server.close()

        it 'should throw', (done) ->
            @client.get "test-path/", (error, response, body) =>
                should.exist error
                should.exist body
                body.should.be.equal '{"this:"isnotjson}'
                error.message.should.have.string '{"this:"isnotjson}'
                done()

describe "Files", ->

    describe "client.saveFile", ->

        before ->
            @app = fakeDownloadServer '/test-file', './README.md'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            fs.unlinkSync './dl-README.md'
            @server.close()

        it "When I send get request to server", (done) ->
            @client.saveFile 'test-file', './dl-README.md', \
                             (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 200
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './dl-README.md'
            resultStats.size.should.equal fileStats.size

    describe "client.saveFileAsStream", ->

        before ->
            @app = fakeDownloadServer '/test-file', './README.md'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            fs.unlinkSync './dl-README.md'
            @server.close()

        it "When I send get request to server", (done) ->
            stream = @client.saveFileAsStream 'test-file', (err, res, body) =>
                should.not.exist err
                res.statusCode.should.be.equal 200
                done()
            stream.pipe fs.createWriteStream './dl-README.md'

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './dl-README.md'
            resultStats.size.should.equal fileStats.size


    describe "client.sendFile", ->

        before ->
            @app = fakeUploadServer '/test-file', './up'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            for name in fs.readdirSync './up'
                fs.unlinkSync(path.join './up', name)
            fs.rmdirSync './up'
            @server.close()

        it "When I send post request to server", (done) ->
            file = './README.md'
            @client.sendFile 'test-file', file, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 201
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './up/README.md'
            resultStats.size.should.equal fileStats.size

    describe "client.sendFileFromStream", ->

        before ->
            @app = fakeUploadServer '/test-file', './up'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            fs.unlinkSync './up/README.md'
            fs.rmdirSync './up'
            @server.close()

        it "When I send post request to server", (done) ->
            @file = fs.createReadStream './README.md'
            @client.sendFile 'test-file', @file, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 201
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './up/README.md'
            resultStats.size.should.equal fileStats.size


    describe "client.sendManyFiles", ->

        before ->
            @app = fakeUploadServer '/test-file', './up'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            fs.unlinkSync './up/README.md'
            fs.unlinkSync './up/package.json'
            fs.rmdirSync './up'
            @server.close()

        it "When I send post request to server", (done) ->
            @file = './README.md'
            @file2 = './package.json'
            files = [@file, @file2]
            @client.sendFile 'test-file', files, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 201
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './up/README.md'
            resultStats.size.should.equal fileStats.size
            fileStats = fs.statSync './package.json'
            resultStats = fs.statSync './up/package.json'
            resultStats.size.should.equal fileStats.size

    describe "client.sendManyFilesMixingStreamAndPaths", ->

        before ->
            @app = fakeUploadServer '/test-file', './up'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            fs.unlinkSync './up/README.md'
            fs.unlinkSync './up/package.json'
            fs.rmdirSync './up'
            @server.close()

        it "When I send post request to server", (done) ->
            @file = './README.md'
            @file2 = fs.createReadStream './package.json'
            files = [@file, @file2]
            @client.sendFile 'test-file', files, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 201
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './up/README.md'
            resultStats.size.should.equal fileStats.size
            fileStats = fs.statSync './package.json'
            resultStats = fs.statSync './up/package.json'
            resultStats.size.should.equal fileStats.size

    describe "client.sendManyFilesFromStream", ->

        before ->
            @app = fakeUploadServer '/test-file', './up'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            fs.unlinkSync './up/README.md'
            fs.unlinkSync './up/package.json'
            fs.rmdirSync './up'
            @server.close()

        it "When I send post request to server", (done) ->
            @file = fs.createReadStream './README.md'
            @file2 = fs.createReadStream './package.json'
            files = [@file, @file2]
            @client.sendFile 'test-file', files, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 201
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './up/README.md'
            resultStats.size.should.equal fileStats.size
            fileStats = fs.statSync './package.json'
            resultStats = fs.statSync './up/package.json'
            resultStats.size.should.equal fileStats.size

    describe "client.putFile", ->

        before ->
            @app = fakePutServer '/test-file', './up'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            for name in fs.readdirSync './up'
                fs.unlinkSync(path.join './up', name)
            fs.rmdirSync './up'
            @server.close()

        it "When I send put request to server", (done) ->
            file = './README.md'
            @client.putFile 'test-file', file, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 201
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './up/file'
            resultStats.size.should.equal fileStats.size

    describe "client.putFileFromStream", ->

        before ->
            @app = fakePutServer '/test-file', './up'
            @server = @app.listen 8888
            @client = request.createClient "http://localhost:8888/"

        after ->
            fs.unlinkSync './up/file'
            fs.rmdirSync './up'
            @server.close()

        it "When I send put request to server", (done) ->
            @file = fs.createReadStream './README.md'
            @client.putFile 'test-file', @file, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 201
                done()

        it "Then I receive the correct file", ->
            fileStats = fs.statSync './README.md'
            resultStats = fs.statSync './up/file'
            resultStats.size.should.equal fileStats.size

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
            @client = request.createClient "http://localhost:8888/"

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
            @client = request.createClient "http://localhost:8888/"

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
            @client = request.createClient "http://localhost:8888/"

        after ->
            @serverPost.close()

        it "When I send setToken request", (done) ->
            @client.setToken 'cozy'
            data = postData:"data test"
            @client.post "test-path/", data, (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 200
                @body = body
                done()

        it "Then I get msg: ok as answer.", ->
            should.exist @body.msg
            @body.msg.should.equal "ok"

describe "Set OAuth2 bearer token", ->

    describe "authentified client.get", ->

        before ->
            @serverGet = fakeServer msg:"ok", 200, (body, req) ->
                bearerToken = req.headers['authorization']
                bearerToken.should.equal 'Bearer cozy' # Check that the bearer prefix has been added
                req.method.should.equal "GET"
                req.url.should.equal "/test-path/"
            @serverGet.listen 8888
            @client = request.createClient "http://localhost:8888"

        after ->
            @serverGet.close()

        it "When I send setBearerToken request", (done) ->
            @client.setBearerToken 'cozy'
            @client.get "test-path/", (error, response, body) =>
                should.not.exist error
                response.statusCode.should.be.equal 200
                @body = body
                done()

        it "Then I get msg: ok as answer.", ->
            should.exist @body.msg
            @body.msg.should.equal "ok"

describe "Set header on request", ->

    before ->
        @serverReq = fakeServer msg:"ok", 200, (body, req) ->
            contentType = req.headers['content-type']
            contentType.should.equal 'application/json-patch+json'
            req.method.should.equal 'PATCH'
            req.url.should.equal  "/test-path/"
        @serverReq.listen 8888
        @client = request.createClient "http://localhost:8888/"

    after ->
        @serverReq.close()

    it "When I send a patch with a custom content type", (done) ->
        options = { headers: {} }
        options.headers['content-type'] = 'application/json-patch+json'
        @client.patch "test-path/", {}, options, (error, response, body) =>
            should.not.exist error
            response.statusCode.should.be.equal 200
            @body = body
            done()

    it "Then I get msg: ok as answer.", ->
        should.exist @body.msg
        @body.msg.should.equal "ok"
