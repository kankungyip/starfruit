#
#       _/_/_/    _/                              _/_/                      _/    _/      
#    _/        _/_/_/_/    _/_/_/  _/  _/_/    _/      _/  _/_/  _/    _/      _/_/_/_/   
#     _/_/      _/      _/    _/  _/_/      _/_/_/_/  _/_/      _/    _/  _/    _/        
#        _/    _/      _/    _/  _/          _/      _/        _/    _/  _/    _/         
# _/_/_/        _/_/    _/_/_/  _/          _/      _/          _/_/_/  _/      _/_/      
#
# MIT Licensed
# Copyright (c) 2014 Kan Kung-Yip
#
# Command Line Tool

# Module dependencies
fs = require 'fs'
os = require 'os'
path = require 'path'
util = require 'util'
cluster = require 'cluster'
readline = require 'readline'
{spawn} = require 'child_process'

# environment
env = process.env.NODE_ENV or 'development'

# styles
style =
  header: (str) -> '\x1b[1;4m' + str + '\x1b[0m'
  int: (str) -> '\x1b[34m' + str + '\x1b[0m'
  tag: (str) -> '\x1b[32m' + str + '\x1b[0m'
  error: (str) -> '\x1b[31m' + str + '\x1b[0m'
  warning: (str) -> '\x1b[33m' + str + '\x1b[0m'
  over: (str) -> '\x1b[36m' + str + '\x1b[0m'
  cmd: (str) -> '\x1b[32m' + str + '\x1b[0m'

# cpus
MAX_CPUS = os.cpus().length

# welcome
WELCOME = '\x1b[0;0H\x1b[K\x1b[J
\n                        _  
\n    __ _|_   __   __  _|_  __        o _|_
\n  __)   |_, (__( |  \'  |  |  \' (__(_ |  |_,
\n   
\n
\n'

# helps
USAGE_HELP = '\x1b[1mStarfruit\x1b[0m
\nCopyright (c) 2014 Kan Kung-Yip.
\n
\nUsage: starfruit [environment] [-c <cpus>] [-s <dir>] [-o|d <dir>] [-l <lang>]
\n       starfruit help
\n
\n  Environments:
\n    development, debug        debug, default environment
\n    production, release       release, less message log
\n
\n  Options:
\n    -c, -n, --cpus <cpus>     start server proess, each process uses a cpu
\n                              core, default start 1 process
\n    -s, --source <dir>        coffeescript sources path, default path is src
\n    -o, --out <dir>           coffeescript output path, default path is lib
\n    -d, --dynamic <dir>       dynamic contents path, default path is lib
\n    -l, --language <lang>     programming language:
\n                                - javascript
\n                                - coffeescript
\n                              default language is coffeescript
\n
\n  Commands:
\n    add [<cpus>]              add a server process, each process uses a cpu
\n                              core, default add 1 process
\n    clear                     clear screen
\n    error [[-]<id>]           list all internal errors, check error
\n                              information by error id or delete error by
\n                              error id
\n    help                      commands help infomation
\n    list                      list all server processes
\n    remove <pid>              shutdown a server process by process id
\n    quit                      quit starfruit shell and shutdown all server
\n                              processes
\n
\n  Examples:
\n    starfruit production -c 2
\n    starfruit -c 2 -l coffeescript
\n
\nDocumentation can be found at https://github.com/davedelong/starfruit/wiki'

SHELL_HELP = '\x1b[1mStarfruit\x1b[0m
\nCopyright (c) 2014 Kan Kung-Yip.
\n
\nCommands:
\n  add <cpus>                add a server process, each process uses a cpu
\n                            core, default add 1 process
\n  clear                     clear screen
\n  error [[-]<id>]           list all internal errors, check error
\n                            information by error id or delete error by
\n                            error id
\n  help                      commands help infomation
\n  list                      list all server processes
\n  remove <pid>              shutdown a server process by process id
\n  quit                      quit starfruit shell and shutdown all server
\n                            processes
\n
\n'

# Store all workers
workers = {}

# Store all errors
errors = { index: 0 }

# Show help infomations.
help = (info) -> process.stdout.write info

# Start a server process
start = (env) ->
  worker = cluster.fork "NODE_ENV": env
  worker.on 'message', (err) ->
    errors.index++
    errors[errors.index] = err
  pid = worker.process.pid
  date = new Date()
  year = date.getFullYear()
  month = date.getMonth() + 1
  month = '0' + month if month < 10
  day = date.getDate()
  day = '0' + day if day < 10
  workers[pid] =
    date: util.format '%s-%s-%s %s', year, month, day, date.toLocaleTimeString()
    process: worker
  return pid

# Boot servers cluster
boot = (env, argv) ->
  # boot master cluster
  return unless cluster.isMaster
  console.log 'Node environment: %s', style.header env.toUpperCase()
  basedir = process.cwd()
  # getting argvs
  cpus = 1
  dynamic = 'lib'
  source = 'src'
  language = 'coffeescript'
  while argv.length > 0
    switch argv.shift()
      when '-c', '-n', '--cpus'
        cpus = parseInt argv.shift() if argv[0]?.indexOf '-' < 0
        cpus = 1 if isNaN cpus or cpus < 1
        cpus = MAX_CPUS if cpus > MAX_CPUS
      when '-s', '--source'
        source = argv.shift() if argv[0]?.indexOf '-' < 0
      when '-o', '--out', '-d', '--dynamic'
        dynamic = argv.shift() if argv[0]?.indexOf '-' < 0
      when '-l', '--language'
        switch argv.shift()
          when 'javascript', 'js' then language = 'javascript'
          else console.error style.error 'Only support javascript or coffeescript language, default coffeescript'

  # build source codes
  lib = path.join basedir, dynamic
  src = path.join basedir, source
  if (language is 'coffeescript') and (fs.existsSync src)
    fs.mkdirSync lib unless fs.existsSync lib
    options = ['-w', '-c', '-b', '-o']
    options = options.concat [dynamic, source]
    shell = spawn 'coffee', options
    shell.stderr.pipe process.stderr
    shell.stdout.pipe process.stdout

  # watch dynamic contents folder
  (fs.watch lib, -> restart env, cpus) if fs.existsSync lib

  # when worker exit restart it
  cluster.on 'exit', (worker, code, signal) ->
    pid = worker.process.pid
    delete workers[pid]
    start env if signal isnt 'SIGKILL'
  # found boot file
  filename = path.join basedir, 'index.js'
  unless fs.existsSync filename
    console.error style.error 'Can not found index.js file in ' + basedir
    process.exit 1
  cluster.setupMaster exec: filename
  # running server process
  add env, cpus

# Shutdown server
shutdown = (message = '') ->
  for pid, worker of workers
    worker.auto = false
    process.kill pid
  console.log message
  process.exit 0

# List all workers
list = ->
  i = 0
  message = util.format '\n  %s', style.header '\tPID\tTIME                  '
  for pid, worker of workers
    message += util.format '\n   %d\t%s\t%s', ++i, style.int(pid), worker.date
  console.log message + '\n'

# Add server process
add = (env, cpus) ->
  if cpus? then cpus = parseInt cpus else cpus = 1
  num = (pid for pid of workers).length
  if num < MAX_CPUS
    if cpus > MAX_CPUS - num
      cpus = MAX_CPUS - num
      console.log (if cpus > 1 then 'Only adding %s processes' else 'Only adding %s process'), style.int cpus
    if cpus < 1 then cpus = 1
    num += cpus
    while cpus > 0
      start env
      cpus--
    return console.log (if num > 1 then '%s processes are running\n' else '%s process is running\n'), style.int num
  console.log 'Max running %s processes, use %s command look all processes\n', style.int(MAX_CPUS), style.cmd('list')

# Remove worker by pid of process
remove = (pid) ->
  return console.log 'Usage: %s <pid>\n', style.cmd 'remove' unless pid
  return console.error '%s\n', style.error 'Not found pid ' + pid unless workers.hasOwnProperty pid
  return console.error style.warning 'Can not shutdown the last server process\n' if (pid for pid of workers).length = 1
  worker = workers[pid].process
  worker.disconnect()
  worker.kill 'SIGKILL'
  console.log 'Process %s shutdown\n', style.int pid

# Restart all process
restart = ->
  process.kill pid for pid of workers

# Dispaly error infomation
error = (ids) ->
  # select a error
  if ids.length > 0
    for id in ids
      fixed = false
      if id.indexOf('-') is 0
        fixed = true
        id = id.substr 1
      # found error
      return console.log 'Can not found error %s\n', style.int(id) unless errors.hasOwnProperty id
      # error fixed
      if fixed is true
        console.log 'Error %s has done', style.int id
        delete errors[id]
      # error information
      else
        err = errors[id]
        req = err.request
        res = err.response
        console.log '
        \n  %s
        \n   %s
        \n  %s
        \n   %s %s
        \n  %s
        \n   %s - %s
        \n  %s
        \n   method:       %s
        \n   url:          %s
        \n  %s
        \n   file:         %s
        \n   status code:  %s
        \n   elapsed time: %sms
        ',
          style.header('                          error id '),
          style.int id
          style.header('                              time '),
          err.date, err.time,
          style.header('                           message '),
          err.title, err.message,
          style.header('                    client request '),
          style.tag(req.method),
          req.url,
          style.header('                   server response '),
          res.file,
          res.statusCode,
          res.elapsedTime
    console.log '' # blank line

  # list all errors
  else
    message = ''
    for id, err of errors
      if typeof err is 'object'
        text = util.format '\n   %d\t%s', id, err.message
        if text.length > 70
          text = util.format '%s...%s', text.substr(0, 40), text.substr(text.length - 27)
        message += text
    message = style.over '\n\tNo error' if message.length is 0
    console.log util.format '\n  %s%s\n', style.header('\tERRORS                            '), message

# Quit starfruit shell
quit = (resolve) ->
  switch resolve
    when 'yes', 'y' then shutdown 'Bye!'
    when 'no', 'n' then console.log ''; return [null, '']
    else return ['quit', style.warning 'ARE YOU SURE? (yes|y|no|n)']

# Welcome screen
process.stdout.write WELCOME

# Getting user options
argv = process.argv.slice 2
env = argv.shift().toLowerCase() if argv.length > 0 and argv[0].indexOf('-') < 0
if env is 'release' then env = 'production'
if env is 'debug' then env = "development"
switch env
  when 'help', '?' then shutdown USAGE_HELP
  when 'production', 'development' then boot env, argv

# Build a starfruit shell
shell = readline.createInterface
  input: process.stdin
  output: process.stdout
shell.confirm = false
shell.on 'SIGINT', ->
  shutdown 'Bye!' if shell.confirm
  shell.confirm = true
  console.log style.warning 'Press Control-C again to exit'

# Running starfruit shell
do repl = (message = '', confirm = null) ->
  shell.question message, (answer) ->
    # split comand and argv
    tmp = answer.split ' '
    command = tmp.shift()
    argv = tmp
    # confirm command
    if typeof confirm is 'string'
      resolve = command
      command = confirm
    # command action
    shell.confirm = false
    switch command
      when 'add' then add env, argv[0]
      when 'clear', 'cls' then process.stdout.write '\x1b[0;0H\x1b[K\x1b[J'
      when 'error', 'err' then error argv
      when 'help', '?' then help SHELL_HELP
      when 'list', 'ls' then list()
      when 'remove', 'rm' then remove argv[0]
      when 'restart' then restart()
      when 'quit', 'exit' then [confirm, message] = quit resolve
      # error command
      else console.error style.error command + ': command not found\n' if command.length > 0
    repl message, confirm
