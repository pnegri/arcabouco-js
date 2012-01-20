#     Arcabouco.JS
#     (c) 2011 Patrick Negri, Yellers Software
#     Arcabouco.JS is freely distributable under the MIT license.
#     For all details and documentation:
#     http://github.com/pnegri/arcabouco-js

# Helpers & Setup
# ---------------

# Require our external dependencies, place all inside Common
Common = require __dirname + '/common'

# Patch node with some features
require __dirname + '/_monkey-patching'

class Arcabouco

    # Configuration
    config               : {}

    Template             : null
    Content              : null
    ObjectPool           : null
    Controller           : null
    Request              : null

    # Content Manager and Injector
    
    putContentFor        : ( where, data, options = { group: 'default' } ) ->
      return false unless @Content
      @Content.putContentFor where, data, options

    getContentFor        : ( where, options = { group: 'default' } ) ->
      return false unless @Content
      @Content.getContentFor where, options

    # Object Compiler

    assemble             : ( directory ) ->
      fullPath = Common.Path.normalize( directory )
      if Common.Path.existsSync( fullPath )
        files = Common.Fs.readdirSyncR( fullPath )
        for file in files
          valid = false
          if file.match /\.js/gi
            valid = true
          if file.match /\.coffee/gi
            valid = true
          if file.match /src\//gi
            valid = false
          if file.match /\.swp/gi
            valid = false
          if valid
            @work require file

    work: ( object_piece ) ->
      index = @Controller.register( object_piece, this )
      @Request.parseRoutes( index, this )

    build                : (development=false) ->
      return false unless @ObjectPool
      @ObjectPool.build( this, development )

    registerObject       : ( object, options = {} ) ->
      return false unless @ObjectPool
      @ObjectPool.registerObject object, options

    getObject            : ( object ) ->
      return false unless @ObjectPool
      @ObjectPool.getObject object

    #registerObject      : null
    #createObject        : null
    
    loadTemplate         : ( file, name ) ->
      return false unless @Template
      @Template.loadTemplate file, name

    loadTemplateString   : ( string, name ) ->
      return false unless @Template
      @Template.loadTemplateString string, name

    buildParamsForRender: ( moreParams ) ->
      params = {}
      params['content_for'] = this.getContentFor.bind(this)
      Common._.extend( params, moreParams )
      params

    render               : ( file, context = this, params = {}, layout = 'layout.haml' ) ->
      return false unless @Template
      output_params = @buildParamsForRender( params )
      @Template.doRender file, context, output_params, layout

    renderPartial        : ( file, context = this, params = {} ) ->
      return false unless @Template
      output_params = @buildParamsForRender( params )
      @Template.doRenderPartial file, context, output_params

    dispatch             : ( request, response ) ->
      return null unless @Request

      # Extend Request with Application
      request.application = this
      # Extend Response with Application
      response.application = this

      @Request.dispatch( request, response )
    
    createServer         : ->
      Common.Http.createServer( @dispatch.bind( this ) )

    createSecureServer   : ( privateKey, certificate ) ->
      credentials = Common.Crypt.createCredentials {
        key  : privateKey
        cert : certificate
      }
      secureServer = Common.Http.createServer( @dispatch.bind( this ) )
      secureServer.setSecure( credentials )
      secureServer

    configurePackage    : ( name, packages ) ->
      if packages[name]
        this[ name ] = new packages[ name ]
      else
        localRequirement = require __dirname + "/arcabouco_modules/" + name.toLowerCase()
        this[ name ] = new localRequirement()

    # The Application Fabric
    # ----------------------
    #
    # A constructor must be called with a configuration options.
    # These configurations can change everything because all
    # our functions are just a proxy to internal components.
    constructor         : ( @config = {} ) ->

      # Try to use some user defined packages if they are sent
      packages = if @config.packages then @config.packages else {}

      # Load the packages checking for a user defined one, use a default if none is suplied
      for packageName in ['Template','Content','ObjectPool','Controller','Request']
        @configurePackage( packageName + '', packages )

      # Configure delegated methods
      @loadTemplate Common.Path.normalize(__dirname + '/../templates/404.haml'), '404'
      @loadTemplate Common.Path.normalize(__dirname + '/../templates/500.haml'), '500'

module.exports = Arcabouco
