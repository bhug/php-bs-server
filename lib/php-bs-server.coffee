PhpServerView = require './php-bs-server-view'
PhpServerServer = require './php-bs-server-server'
PhpServerBS = require './php-bs-server-browser-sync'
open = require 'open'
fs = require 'fs'

module.exports =
  config:
    phpPath:
      title: 'Path to PHP Executable'
      description: 'On Windows this might need to be the full path to php.exe'
      type: 'string'
      default: 'php'
    localhost:
      title: 'Hostname to use'
      type: 'string'
      default: 'localhost'
    startPort:
      title: 'Default port to bind to'
      description: 'Will search for an empty port starting from here'
      type: 'integer'
      default: 8000
    phpIni:
      title: 'Custom php.ini file'
      description: 'Will replace your standard CLI php.ini settings'
      type: 'string'
      default: ''
    overrideErrorlog:
      title: 'Override error log'
      description: 'Redirect error log to panel in Atom. Overrides ini settings. May not work on Windows'
      type: 'boolean'
      default: false
    expandOnLog:
      title: 'Expand on log message'
      description: 'Expands the server console window when selected requests are received by the server'
      type: 'string'
      enum: ['all', 'none']
      default: 'all'
    openInBrowser:
      title: 'Open in browser (deprecated)'
      description: 'Open browser at local URL on server start'
      type: 'boolean'
      default: true


  server: null
  view: null


  activate: ->
    atom.commands.add 'atom-workspace', "php-bs-server:start", => @start()
    atom.commands.add 'atom-workspace', "php-bs-server:start-tree", => @startTree()
    atom.commands.add 'atom-workspace', "php-bs-server:start-public", => @start(atom.project.getPaths()[0]+'/public/')

  deactivate: ->
    @stop()


  startTree: ->
    @start atom.packages.getLoadedPackage('tree-view').mainModule.treeView.selectedPath


  startTreeRoute: ->
    [path, basename] = @splitPath atom.packages.getLoadedPackage('tree-view').mainModule.treeView.selectedPath
    @start path, basename


  startDocument: ->
    @start(atom.workspace.getActiveTextEditor()?.getPath())


  splitPath: (path) ->
    basename = false
    if !fs.lstatSync(path).isDirectory()
      basename = path.split(/[\\/]/).pop()
      path = path.substring(0, Math.max(path.lastIndexOf("/"), path.lastIndexOf("\\")))

    return [path, basename]

  start: (documentroot, router) ->
    # Stop server if currently running
    if @server
      @server.stop()
      @server = null

    # Set up panel
    if !@view
      @view = new PhpServerView(
        title: "PHP Server: Launching..."
      )
      @view.setServer(this)

    @view.attach()
    @view.clear()

    # Collapse view if expandOnLog is set to none
    if atom.config.get('php-bs-server.expandOnLog') == 'none'
      @view?.hide()

    # Launch server in given working directory
    if !documentroot
      documentroot = atom.project.getPaths()[0]

    if !documentroot
      @view.addError "PHP Server could not launch"
      @view.addError "Atom project directory not found"
      return

    [documentroot, basename] = @splitPath documentroot

    @server = new PhpServerServer documentroot, router

    # Pass package settings
    @server.path = atom.config.get('php-bs-server.phpPath')
    @server.host = atom.config.get('php-bs-server.localhost')
    @server.basePort = atom.config.get('php-bs-server.startPort')
    @server.ini = atom.config.get('php-bs-server.phpIni')
    @server.overrideErrorlog = atom.config.get('php-bs-server.overrideErrorlog')

    # Listen
    @server.on 'message', (message) =>
      @view?.addMessage message, atom.config.get('php-bs-server.expandOnLog')

    @server.on 'error', (err) =>
      console.error err

      if @view
        if err.code == 'ENOENT'
          @view.addError "PHP Server could not launch"
          @view.addError "Have you defined the right path to PHP in your settings? Using #{@server.path}"
        else if err.code == 'ENOTDIR'
          @view.addError "PHP Server could not launch"
          @view.addError "Not a directory? Using #{@server.documentRoot}"
        else
          @view.addError err.message

    # Start php server
    @server.start =>
        @view.setTitle "PHP Server started: <a href=\"#{@server.href}\">#{@server.href}</a>", atom.config.get('php-bs-server.expandOnLog')
        @view.addMessage "Document root is #{@server.documentRoot}", atom.config.get('php-bs-server.expandOnLog')
        @view.addMessage "PHP Server listening on #{@server.href}", atom.config.get('php-bs-server.expandOnLog')

        # -- Start Browsersync server
        @bsconfigfile = atom.project.getPaths()[0]+'/bs-config.js'
        @bsserver = new PhpServerBS
        @bsserver.setConfigFile(@bsconfigfile)
        @bsserver.start =>
            @view.setTitle "Browsersync Server started : <a href=\"#{@bsserver.href}\">#{@bsserver.href}</a>", atom.config.get('php-bs-server.expandOnLog')
            @view.addMessage "Browsersync Server listening on #{@bsserver.href}", atom.config.get('php-bs-server.expandOnLog')

  stop: ->
    @server?.stop()
    @bsserver?.stop()
    @server = null
    @bsserver = null
    @view = null

  clear: ->
    @view?.clear()
