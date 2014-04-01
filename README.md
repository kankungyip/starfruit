# Starfruit
A compact and intelligent web application framework for Node.js.

## Installation
```
$ sudo npm install -g starfruit
```

## Usage
### Simple web server
All static resource files in ./pub folder.
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

### Customized server status code page
Use ```_<status code>.html``` file to customize the server status code page, such as ```_404.html```. All server status code page must in ./pub folder or customized static content folder.

### Command line tool
* ```$ cd MyProject```
* Boot server ```$ starfruit``` or ```$ sf```
* Add 2 server process ```add 2```
* List all server processes ```list``` or ```ls```
* Shutdown a process ```remove <pid>``` or ```rm <pid>```
* Quit ```quit```

## Histroy
### 0.1.0
+ Static web server
+ Real-time command line tool

## License
See [LICENSE](https://github.com/kankungyip/starfruit/blob/master/LICENSE).
