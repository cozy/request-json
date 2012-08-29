fs = require 'fs'
{exec} = require 'child_process'

task 'tests', 'run tests through mocha', ->
  console.log "Run tests with Mocha..."
  command = "mocha tests.coffee --reporter spec "
  command += "--require should --compilers coffee:coffee-script --colors"
  exec command, (err, stdout, stderr) ->
    if err
      console.log "Running mocha caught exception: \n" + err
    console.log stdout

task "xunit", "", ->
  process.env.TZ = "Europe/Paris"
  command = "mocha tests.coffee"
  command += " --require should --compilers coffee:coffee-script -R xunit > xunit.xml"
  exec command, (err, stdout, stderr) ->
    console.log stdout

task "build", "", ->
  console.log "Compile main file..."
  command = "coffee -c main.coffee"
  exec command, (err, stdout, stderr) ->
    if err
      console.log "Running coffee-script compiler caught exception: \n" + err
    else
      console.log "Compilation succeeds."
      
    console.log stdout
