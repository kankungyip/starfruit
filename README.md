```

        _/_/_/    _/                              _/_/                      _/    _/      
     _/        _/_/_/_/    _/_/_/  _/  _/_/    _/      _/  _/_/  _/    _/      _/_/_/_/   
      _/_/      _/      _/    _/  _/_/      _/_/_/_/  _/_/      _/    _/  _/    _/        
         _/    _/      _/    _/  _/          _/      _/        _/    _/  _/    _/         
  _/_/_/        _/_/    _/_/_/  _/          _/      _/          _/_/_/  _/      _/_/      

```
A compact and intelligent web application framework for Node.js.

[中文介绍](https://github.com/kankungyip/starfruit/wiki/%E4%BB%8B%E7%BB%8D).

## Installation
```
$ sudo npm install -g starfruit
```

## Features
1. **Compact**, only 3 core files
2. **Intelligent**, automatic route load file
3. **Security**, controller sandbox operation, automatic restart when crashes
4. **Automatic**, add new controller codes without shutdown, automatically compile and load
5. **Multi-core** take advantage of multi-core processing, multi-process server
6. **Real-time**, real-time monitoring server command-line tool

## Quick Start
### Simple web server
All static resource files in `MyProject/pub` folder.

```js
// index.js
var sf = require('starfruit')
  , fs = require('fs');

app = sf();
app.log(fs.createWriteStream('./starfruit.log', { flags: "a" }));
app.listen(8080);
```

HTTPS server:

```js
// index.js
var sf = require('starfruit')
  , fs = require('fs')
  , https = require('https');

app = sf();
app.log(fs.createWriteStream('./starfruit.log', { flags: "a" }));

var options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
};

https.createServer(options, app).listen(9090);
```

### Dynamic controller
For controlling the flow of the application, which handles the events and to respond. "Events" includes changing the user's behavior and data model.

All dynamic files (`.js`) in `MyProject/lib` folder, CoffeeScript source files (`.coffee`) in `MyProject/src` folder, resource files (`.html`) in `MyProject/res` folder.

```js
// app.js
// route: yoururl.com/app
var fs = require('fs')
  , sf = require('starfruit');

module.exports = app = new sf.Controller();

app.render = function() {
  $ = this;
  $.sandbox(function() {
    $.writeHead(200, { "Content-Type": "text/html;charset=utf-8" });
    $.receive(fs.createReadStream('app.html'));
  });
};

app.timeClick = function() {
  $ = this;
  $.model({
    time: ["text", "style"]
  });
  if ($.data) {
    $.data.time.text = new Date().toString();
    $.data.time.style = 'color:blue';
    $.end();
  }
};

app.helloClick = function() {
  $ = this;
  $.model({
    username: "value",
    message: "text"
  });
  if ($.data) {
    if ($.data.username) {
      $.data.message = 'hello ' + $.data.username + ', welcome to starfruit world.';
    }
    $.end();
  }
};
```

or maybe you more like CoffeeScript codes:

```coffee
# app.coffee
# route: yoururl.com/app
fs = require 'fs'
{Controller} = require 'starfruit'

module.exports = class App extends Controller
  render: ->
    @sandbox =>
      @writeHead 200, "Content-Type": "text/html;charset=utf-8"
      @receive fs.createReadStream 'res/app.html'

  timeClick: ->
    @model
      time: ["text", "style"]
    return unless @data
    @data.time.text = new Date().toString()
    @data.time.style = 'color:blue'
    @end()

  helloClick: ->
    @model
      username: "value"
      message: "text"
    return unless @data
    @data.message = "hello #{@data.username}, welcome to starfruit world." if @data.username
    @end()
```

`app.html` contents:

```html
<html>
  <head>
    <title>Demo</title>
    <script src="http://cdn.bootcss.com/jquery/2.1.0/jquery.min.js"></script>
    <script src="/?script"></script>
  <head>
  <body>
    <p><img src="/logo.jpg" /></p>
    <p>Server time: <span style="color:red" id="time">?</span>
      <input type="button" value="Get" onclick="app.selector('timeClick')" />
    </p>
    <p>Your name:
      <input id="username" type="text" />
      <input type="button" value="Hello" onclick="app.selector('helloClick')" />
      <p id="message"></p>
    </p>
  </body>
</html>
```

### Customized server status code page
Use `_<status code>.html` file to customize the server status code page, such as `_404.html`. All server status code page must in `MyProject/pub` folder or customized static content folder.

### Command line tool
* `$ cd MyProject`
* Boot server(enter real-time command line tool) `$ starfruit` or `$ sf`
* Add server process(maximum number of processes CPU cores) `add <num>`
* List all server processes `list` or `ls`
* List all internal errors `error` or `err`
* Check a error `error <id>` or `err <id>`
* Delete a error `error -<id>` or `err -<id>`
* Shutdown a process `remove <pid>` or `rm <pid>`
* Quit `quit`

## APIs
* [`require('starfruit')`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit)
    - [`sf ()`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit#sf)
    - [`sf.log (format, [...])`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit#log_format)
    - [`class: sf.Controller`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit#class_sf_controller)
* [`class: Server`](https://github.com/kankungyip/starfruit/wiki/API:-Server)
    - [`server.timeout`](https://github.com/kankungyip/starfruit/wiki/API:-Server#timeout)
    - [`server.dynamic`](https://github.com/kankungyip/starfruit/wiki/API:-Server#dynamic)
    - [`server.static`](https://github.com/kankungyip/starfruit/wiki/API:-Server#static)
    - [`server.default`](https://github.com/kankungyip/starfruit/wiki/API:-Server#default)
    - [`server.contentType (extname, [type])`](https://github.com/kankungyip/starfruit/wiki/API:-Server#contenttype_extname_type)
    - [`server.listen (port)`](https://github.com/kankungyip/starfruit/wiki/API:-Server#listen_port)
    - [`server.error (callback)`](https://github.com/kankungyip/starfruit/wiki/API:-Server#error_callback)
    - [`server.log (writeStream, [callback])`](https://github.com/kankungyip/starfruit/wiki/API:-Server#log_writestream_callback)
    - [`server.log (callback)`](https://github.com/kankungyip/starfruit/wiki/API:-Server#log_callback)
    - [`server.log (format, [...])`](https://github.com/kankungyip/starfruit/wiki/API:-Server#log_format)
* [`class: Controller`](https://github.com/kankungyip/starfruit/wiki/API:-Controller)
    - [`controller.query`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#query)
    - [`controller.data`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#data)
    - [`controller.parse (raw)`](https://github.com/kankungyip/starfruit/wiki/API:-Controllerhttps://github.com/kankungyip/starfruit/wiki/API:-Controller#parse_raw)
    - [`controller.end ([data], [encoding])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#end_data_encoding)
    - [`controller.write (chunk, [encoding])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#write_chunk_encoding)
    - [`controller.writeHead (statusCode, [headers])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#writeHead_statusCode_headers)
    - [`controller.receive (readStream, [encoding])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#receive_readstream_encoding)
    - [`controller.render ()`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#render)
    - [`controller.sandbox (callback)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#sandbox_callback)
    - [`controller.remote (callback, [argv])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#remote_callback_argv)
    - [`controller.model (model)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#model_model)
    - [`controller.model (template, model)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#model_template_model)
    - [`controller.model (callback, model)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#model_callback_model)
    - [Events](https://github.com/kankungyip/starfruit/wiki/API:-Controller#events)

## Histroy
### 0.2.1
Added:

+ Data model (base)
+ Demo with CoffeeScript

Changed:

* controller.script(...) -> controller.remote(...)

### 0.2.0
Added:

+ Server and client communication events
+ Limit the number of error log

Optimized:

* Server

### 0.1.9
Added:

+ Dynamic controller
+ Error messages pool
+ Check error command

Fixed:

* Command line tool bugs

### 0.1.0
+ Static web server
+ Real-time command line tool

## License
See [LICENSE](https://github.com/kankungyip/starfruit/blob/master/LICENSE).

Copyright (c) 2014 [Kan Kung-Yip](mailto:kan@kungyip.com)
