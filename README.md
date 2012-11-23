## About

Request is a great client for NodeJS, but if you deal only with JSON, things
could be more straightforward. This lib aims to simplify Request usage for 
JSON only requests.

## Install

Add it to your package json or run: 

    npm install request-json

## How it works

```javascript
Client = require('request-json').JsonClient
client = new Client 'http://localhost:8888/'

data = title: 'my title', content: 'my content'
client.post 'posts/', data, (err, res, body) ->
    print response.statusCode

client.get 'posts/', (err, res, body) ->
    print body.rows[0].title

data = title: "my new title"
client.put 'posts/123/', (err, res, body) ->
    print response.statusCode

client.del 'posts/123/', (err, res, body) ->
    print response.statusCode
```

### Extra : files

```javascript
data = name: "test"
client.sendFile 'attachments/', './test.png', data, (err, res, body) ->
    console.log err if err

client.saveFile 'attachments/test.png', './test-get.png', (err, res, body) ->
    console.log err if err
    resultStats = fs.statSync('./test-get.png')
```

### Extra : basic authentication

```javascript
client.setBasicAuth('john', 'secret')
client.get 'private/posts/', (err, res, body) ->
    print body.rows[0].title
```
