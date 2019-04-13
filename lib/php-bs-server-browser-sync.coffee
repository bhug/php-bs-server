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
            host: 'localhost'
            port: '8080'
            open: 'local'
            ui: false
            notify: false
            cwd: atom.project.getPaths()[0]
            logLevel: 'silent'
        }

        constructor: (proxy) ->
            @defaultConfig.proxy = proxy

        start: (callback) ->
            @stop()

            try

                @browserSyncServer = require("browser-sync").create() ;
                @config = Object.assign(@defaultConfig, require(@configFile))

                console.log "[php-bs-server:INFO] Starting Browsersync server (proxying #{@config.proxy})"
                console.debug "[php-bs-server:DEBUG] Config file : #{@configFile}", @config
                @browserSyncServer.init(@config, =>
                    @serverPort = @browserSyncServer.getOption('port')
                    @href = "http://#{@config.host}:#{@serverPort}"
                    console.log "[php-bs-server:INFO] Browsersync server started on http://#{@config.host}:#{@serverPort}"
                    console.debug "[php-bs-server:DEBUG] Browsersync server : ", @browserSyncServer
                    callback? ()
                ) ;

            catch err
                console.error err

        stop: (callback) ->
            if @browserSyncServer
                @browserSyncServer.exit() ;
                @browserSyncServer = null;
            callback? ()

        destroy: ->
            @stop()
