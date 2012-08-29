## About

Request is a great client for NodeJS, but at Cozy we just use a small part of
it : simple get, pust, post and delete requests that carry only JSON. This lib
aims to simplify Request usage for these situations.

## How it works

```javascript
Client = require("request-json").JsonClient
client = new Client "http://localhost:8888/"

client.post "posts/", { title: "my title", content:"my content" }, \
            (error, response, body) ->
    print response.statusCode

client.get "posts/", (error, response, body) ->
    print body.rows[0].title

client.put "posts/123/", title: "my new title", (error, response, body) ->
    print response.statusCode

client.del "posts/123/", (error, response, body) ->
    print response.statusCode
```
