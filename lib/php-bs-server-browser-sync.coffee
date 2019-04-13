{spawn} = require 'child_process'

module.exports =
    class PhpServerBrowserSync

        # Settings
        configFile: null

        # Properties
        serverPort: null
        href: null
        config: null

        # Protected
        browserSyncServer: null
        defaultConfig: {
            host:  'localhost'
            port:  '8080'
            ui:    false
            notify:false
            cwd:   atom.project.getPaths()[0]
        }

        constructor: (proxy) ->
            @defaultConfig.proxy = proxy

        start: (callback) ->
            @stop()

            try

                @browserSyncServer = require("browser-sync").create();

                @config = Object.assign(@defaultConfig, require(@configFile))
                console.debug "Config file : #{@configFile}", @config

                @browserSyncServer.init(@config, =>
                    @serverPort = @browserSyncServer.getOption('port')
                    @href = "http://#{@config.host}:#{@serverPort}"
                    console.log "Browsersync server started", @browserSyncServer
                    callback?()
                );

            catch err
                console.error err

        stop: (callback) ->
            if @browserSyncServer
                @browserSyncServer.exit();
                @browserSyncServer = null;
            callback?()

        destroy: ->
            @stop()

        setConfigFile: (configFile) ->
            @configFile = configFile
