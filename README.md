## About

[Request](https://github.com/mikeal/request) is a great HTTP client for NodeJS,
but if you deal only with JSON, things could be more straightforward. This lib
aims to simplify Request usage for 
JSON only requests.

## Install

Add it to your package.json file or run in your project folder: 

    npm install request-json

## Build status

[![Build
Status](https://travis-ci.org/mycozycloud/request-json.png?branch=master)](https://travis-ci.org/mycozycloud/request-json)

## How it works

with Javascript:

```javascript
request = require('request-json');
var client = request.newClient('http://localhost:8888/');

var data = {
  title: 'my title',
  content: 'my content'
};
client.post('posts/', data, function(err, res, body) {
  return console.log(res.statusCode);
});

client.get('posts/', function(err, res, body) {
  return console.log(body.rows[0].title);
});

data = {
  title: 'my new title'
};
client.put('posts/123/', data, function(err, res, body) {
  return console.log(response.statusCode);
});

client.del('posts/123/', function(err, res, body) {
  return console.log(response.statusCode);
});
```

with Coffeescript:

```javascript
request = require('request-json')
client = request.newClient 'http://localhost:8888/'

data = title: 'my title', content: 'my content'
client.post 'posts/', data, (err, res, body) ->
    console.log response.statusCode

client.get 'posts/', (err, res, body) ->
    console.log body.rows[0].title

data = title: 'my new title'
client.put 'posts/123/', data, (err, res, body) ->
    console.log response.statusCode

client.del 'posts/123/', (err, res, body) ->
    console.log response.statusCode
```

### Extra : files

with Javascript:

```javascript
data = {
  name: "test"
};
client.sendFile('attachments/', './test.png', data, function(err, res, body) {
  if (err) {
    return console.log(err);
  }
});

client.saveFile('attachments/test.png', './test-get.png', function(err, res, body) {
  if (err) {
    return console.log(err);
  }
});

```

with Coffeescript:

```javascript
data = name: "test"
client.sendFile 'attachments/', './test.png', data, (err, res, body) ->
    console.log err if err

client.saveFile 'attachments/test.png', './test-get.png', (err, res, body) ->
    console.log err if err
```

sendFile can support file path, stream, array of file path and array of
streams. Each file is stored with the key 'file + index' (file0, file1,
file2...) in the request in case of array. For a single value, it is stored in
the field with key 'file'.


### Extra : basic authentication

with Javascript:

```javascript
client.setBasicAuth('john', 'secret');
client.get('private/posts/', function(err, res, body) {
  return console.log(body.rows[0].title);
});

```


with Coffeescript:

```javascript
client.setBasicAuth 'john', 'secret'
client.get 'private/posts/', (err, res, body) ->
    console.log body.rows[0].title
```
