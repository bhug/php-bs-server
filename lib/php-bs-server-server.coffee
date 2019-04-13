{Emitter} = require 'atom'
{spawn} = require 'child_process'
portfinder = require 'portfinder'

module.exports =
  class PhpServerServer
    # Settings
    path: 'php'
    host: 'localhost'
    basePort: 8000
    ini: ''
    overrideErrorlog: true

    # Properties
    documentRoot: null
    routerFile: null
    href: null

    # Protected
    server: null


    constructor: (@documentRoot, @routerFile) ->
      @emitter = new Emitter


    destroy: ->
      @stop()


    on: (eventName, handler) ->
      @emitter.on eventName, handler


    preempt: (eventName, handler) ->
      @emitter.preempt eventName, handler


    start: (callback) ->
      @stop()

      # Find free port
      portfinder.basePort = @basePort
      portfinder.getPort (err, port) =>
        try
          # Build CLI options
          options = []

          if @overrideErrorlog
            # ini settings for errors to be logged to stderr
            options.push "-d", "error_log=", "-d", "log_errors=1", "-d", "display_errors="

          if @ini
            # Set specified php.ini file
            options.push "-c", @ini

          options.push "-S", "#{@host}:#{port}"

          if @routerFile
            # Use given file as request router
            options.push @routerFile


          # Spawn PHP server process
          @server = spawn @path, options, env: process.env, cwd: @documentRoot

          # Catch process failures
          @server.once 'exit', (code) =>
            @emitter.emit 'error', code if code != 0

          @server.on 'error', (err) =>
            @emitter.emit 'error', err

          # Relay PHP output
          @server.stdout.on 'data', (data) =>
            @_filterMessageAndEmit(data.asciiSlice(), 'message')

          @server.stderr.on 'data', (data) =>
            @_filterMessageAndEmit(data.asciiSlice(), 'message')

          # Record server state
          @href = "http://#{@host}:#{port}"

          # Once process has spawned execute callback
          callback?()

        catch err
          # Failure
          @server = null
          @emitter.emit 'error', code: null, message: err


    stop: (callback) ->
      if @server
        # Replace exit listener
        @server.removeAllListeners 'exit'
        @server.once 'exit', (code) =>
          @server.removeAllListeners

          @href = null

          @server = null
          callback?()

        # Send Ctrl+C
        @server.kill 'SIGINT'


    _filterMessageAndEmit: (message, level) ->
      # message = [Sat Apr 13 12:28:39 2019] 127.0.0.1:36036 [200]: /login
      # console.log '- ' + message.substring(0,48)

      # Filter by HTTP status code
      @reg = /(\[\d\d\d\])/
      @match = @reg.exec message

      if @match
        @statusCode = @match?[1].substring(1,4)
        if @statusCode!='200' and @statusCode!='302'
          @emitter.emit level, message
        # else
        #   console.log 'HTTP status code filtres : ' + @statusCode, {'code':@statusCode,'level':level,'message':message};
      else
        @emitter.emit level, message
