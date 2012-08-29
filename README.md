## About

Request is a great client for NodeJS, but at Cozy we just use a small part of
it : simple get, pust, post and delete requests that carry only JSON. This lib
simplifies Request for this usages.

## How it works

```javascript
client = new Client "http://localhost:8888/"
client.post "posts/", { title: "my title", content:"my content" }, \
            (error, response, body) ->
    print response.statusCode
client.get "posts/", (error, response, body) ->
    print body.rows[0].title
client.put "posts/123/", title: "my new title", (error, response, body) ->
    print response.statusCode
client.delete "posts/123/", (error, response, body) ->
    print response.statusCode
```
