[中文版本](https://github.com/kankungyip/starfruit/wiki/%E6%9B%B4%E6%96%B0%E8%AE%B0%E5%BD%95).

## 0.2.2
Changed:

* controller.remote(...) -> controller.handle(...)
* controller.sandbox(...) -> controller.domain(...)
* controller.writeHead(...) -> controller.set(...)
* Merge controller.receive(...) and controller.write(...)

Deleted:

- Command line error check function commands and error collection

## 0.2.1
Added:

+ Data model (base)
+ Demo with CoffeeScript

Changed:

* controller.script(...) -> controller.remote(...)

## 0.2.0
Added:

+ Server and client communication events
+ Limit the number of error log

Optimized:

* Server

## 0.1.9
Added:

+ Dynamic controller
+ Error messages pool
+ Check error command

Fixed:

* Command line tool bugs

## 0.1.0
+ Static web server
+ Real-time command line tool

Copyright (c) 2014 [Kan Kung-Yip](mailto:kan@kungyip.com)
