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

## Usage
### Simple web server
All static resource files in ```MyProject/pub``` folder.
```javascript
// index.js
var sf = require('starfruit')
  , fs = require('fs');

app = sf();
app.log(fs.createWriteStream('./starfruit.log', { flags: "a" }));
app.listen(8080);
```

HTTPS server:
```javascript
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
All dynamic files(```.js```) in ```MyProject/lib``` folder, coffeescript source files(```.coffee```) in ```MyProject/src``` folder.

JavaScript codes:
```javascript
// test.js
// route: yoururl.com/test
var fs = require('fs')
  , sf = require('starfruit');

module.exports = app = new sf.Controller();

app.respond = function(quest) {
    $ = this;
    $.sandbox(function() {
      $.receive(fs.createReadStream('app.html'));
    });
}
```

CoffeeScript codes:
```coffeescript
# test.coffee
# route: yoururl.com/test
fs = require 'fs'
{Controller} = require 'starfruit'

module.exports = class App extends Controller
  respond: (quest) ->
    @sandbox =>
      @receive fs.createReadStream 'app.html'
```

### Customized server status code page
Use ```_<status code>.html``` file to customize the server status code page, such as ```_404.html```. All server status code page must in ./pub folder or customized static content folder.

### Command line tool
* ```$ cd MyProject```
* Boot server(enter real-time command line tool) ```$ starfruit``` or ```$ sf```
* Add server process(maximum number of processes CPU cores) ```add <num>```
* List all server processes ```list``` or ```ls```
* List all internal errors ```error``` or ```err```
* Check a error ```error <id>``` or ```err <id>```
* Delete a error ```error -<id>``` or ```err -<id>```
* Shutdown a process ```remove <pid>``` or ```rm <pid>```
* Quit ```quit```

## Histroy
### 0.1.9
Added:

+ Dynamic controller
+ Error messages pool
+ Check error command

Fixed:

* Fixed command line tool bugs

### 0.1.0
+ Static web server
+ Real-time command line tool

## License
See [LICENSE](https://github.com/kankungyip/starfruit/blob/master/LICENSE).

Copyright (c) 2014 [Kan Kung-Yip](mailto:kan@kungyip.com)
