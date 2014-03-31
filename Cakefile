# Cakefile for sublime

fs = require 'fs'
{spawn, exec} = require 'child_process'

task 'sbuild', 'compile source', ->
  options = ['-c', '-b', '-o']
  options = options.concat ['lib', 'src']
  app = spawn 'coffee', options
  app.stdout.pipe(process.stdout)
  app.stderr.pipe(process.stderr)
  app.on 'exit', (status) -> console.log ';)' if status is 0
