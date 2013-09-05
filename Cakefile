fs = require 'fs'
{exec} = require 'child_process'

task 'tests', 'run tests through mocha', ->
  console.log 'Run tests with Mocha...'
  command = 'mocha tests.coffee --reporter spec '
  command += '--compilers coffee:coffee-script --colors'
  exec command, (err, stdout, stderr) ->
    console.log stdout
    if err
      console.log "Running mocha caught exception: \n" + err
      process.exit 1
    else
      process.exit 0

task 'build', '', ->
  console.log 'Compile main file...'
  command = 'coffee -c main.coffee'
  exec command, (err, stdout, stderr) ->
    if err
      console.log 'Running coffee-script compiler caught exception: \n' + err
    else
      console.log 'Compilation succeeded.'

    console.log stdout
