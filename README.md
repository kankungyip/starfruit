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
3. **Automatic**, add and modify the code without shutting down the server, and automatically compile load
4. **Security**, automatically restart when the server crashes
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
app.log(fs.createWriteStream('./logger.log', { flags: "a" }));
app.listen(8080);
```

HTTPS server:

```js
// index.js
var sf = require('starfruit')
  , fs = require('fs')
  , https = require('https');

app = sf();
app.log(fs.createWriteStream('./logger.log', { flags: "a" }));

var options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
};

https.createServer(options, app).listen(9090);
```

### Dynamic controller
For controlling the flow of the application, which handles the events and to respond. "Events" includes changing the user's behavior and data model.

All dynamic files (`.js`) in `MyProject/lib` folder, CoffeeScript source files (`.coffee`) in `MyProject/src` folder, resource files (`.layout`) in `MyProject/res` folder.

```js
// app.js
// route: yoururl.com/app
var fs = require('fs')
  , sf = require('starfruit');

module.exports = app = new sf.Controller();

app.init = function() {
  $ = this;
  $.title = 'Starfruit';
  $.layout = 'res/app.layout';
};

app.timeClick = function() {
  $ = this;
  $.model({
    time: ["text", "style"]
  });
  if ($.data) {
    $.data.time.text = new Date().toString();
    $.data.time.style = 'color:blue';
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
  init: ->
    @title = 'Starfruit'
    @layout = 'res/app.layout'

  timeClick: ->
    @model
      time: ["text", "style"]
    return unless @data
    @data.time.text = new Date().toString()
    @data.time.style = 'color:blue'

  helloClick: ->
    @model
      username: "value"
      message: "text"
    return unless @data
    @data.message = "hello #{@data.username}, welcome to starfruit world." if @data.username
```

`app.layout` contents:

```html
<p><img src="/logo.jpg" /></p>
<p>Server time: <span style="color:red" id="time">...</span>
  <input type="button" value="Get" onclick="selector('timeClick')" />
</p>
<p>Your name:
  <input id="username" type="text" />
  <input type="button" value="Hello" onclick="selector('helloClick')" />
  <p id="message"></p>
</p>
```

### Customized server status code page
Use `_<status code>.html` file to customize the server status code page, such as `_404.html`. All server status code page must in `MyProject/pub` folder or customized static content folder.

### Command line tool
* `$ cd MyProject`
* Boot server(enter real-time command line tool) `$ starfruit` or `$ sf`
* Add server process(maximum number of processes CPU cores) `add <num>`
* List all server processes `list` or `ls`
* Shutdown a process `remove <pid>` or `rm <pid>`
* Quit `quit`

## APIs
* [`require('starfruit')`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit)
    - [`sf ()`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit#sf)
    - [`sf.log (format, [...])`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit#log_format)
    - [`class: sf.Controller`](https://github.com/kankungyip/starfruit/wiki/API:-starfruit#class_sf_controller)
* [`class: Server`](https://github.com/kankungyip/starfruit/wiki/API:-Server)
    + [Propertys](https://github.com/kankungyip/starfruit/wiki/API:-Server#propertys)
        - [`server.timeout`](https://github.com/kankungyip/starfruit/wiki/API:-Server#timeout)
        - [`server.dynamic`](https://github.com/kankungyip/starfruit/wiki/API:-Server#dynamic)
        - [`server.static`](https://github.com/kankungyip/starfruit/wiki/API:-Server#static)
        - [`server.default`](https://github.com/kankungyip/starfruit/wiki/API:-Server#default)
    + [Methods](https://github.com/kankungyip/starfruit/wiki/API:-Server#methods)
        - [`server.contentType (extname, [type])`](https://github.com/kankungyip/starfruit/wiki/API:-Server#contenttype_extname_type)
        - [`server.listen (port)`](https://github.com/kankungyip/starfruit/wiki/API:-Server#listen_port)
        - [`server.error (callback)`](https://github.com/kankungyip/starfruit/wiki/API:-Server#error_callback)
        - [`server.log (writeStream, [callback])`](https://github.com/kankungyip/starfruit/wiki/API:-Server#log_writestream_callback)
        - [`server.log (callback)`](https://github.com/kankungyip/starfruit/wiki/API:-Server#log_callback)
        - [`server.log (format, [...])`](https://github.com/kankungyip/starfruit/wiki/API:-Server#log_format)
* [`class: Controller`](https://github.com/kankungyip/starfruit/wiki/API:-Controller)
    + [Propertys](https://github.com/kankungyip/starfruit/wiki/API:-Controller#propertys)
        - [`controller.query`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#query)
        - [`controller.data`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#data)
    + [Methods](https://github.com/kankungyip/starfruit/wiki/API:-Controller#methods)
        - [`controller.render ()`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#render)
        - [`controller.parse (raw)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#parse_raw)
        - [`controller.domain (callback)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#domain_callback)
        - [`controller.handle (callback, [argv])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#handle_callback_argv)
        - [`controller.set (headers)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#set_headers)
        - [`controller.write (chunk, [encoding])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#write_chunk_encoding)
        - [`controller.write (readStream, [encoding])`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#write_readstream_encoding)
        - [`controller.model (models)`](https://github.com/kankungyip/starfruit/wiki/API:-Controller#model_models)
    + [Data Model](https://github.com/kankungyip/starfruit/wiki/API:-Controller#datamodel)
        - [Base](https://github.com/kankungyip/starfruit/wiki/API:-Controller#base)
        - [List and Item](https://github.com/kankungyip/starfruit/wiki/API:-Controller#listitem)
        - [Advanced](https://github.com/kankungyip/starfruit/wiki/API:-Controller#advanced)
    + [Events](https://github.com/kankungyip/starfruit/wiki/API:-Controller#events)

## Histroy
See [histroy](https://github.com/kankungyip/starfruit/wiki/History).

## License
See [LICENSE](https://github.com/kankungyip/starfruit/blob/master/LICENSE).

Copyright (c) 2014 [Kan Kung-Yip](mailto:kan@kungyip.com)
