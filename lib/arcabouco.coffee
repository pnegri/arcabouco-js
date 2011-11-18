Common = require __dirname + '/common'
Underscore = require 'underscore'
require __dirname + '/_monkey-patching'

Template = require __dirname + '/template'

class ContentGenerator
  contentArray        : []

  ensureArray: ( where, group ) ->
    @contentArray[ group ] = [] unless @contentArray[ group ]
    @contentArray[ group ][ where ] = [] unless @contentArray[ group ][ where ]
    true

  addContentFor: ( where, data, options = { group: 'default' } ) ->
    priority = 0
    priority = options.priority if options.priority

    group = 'default'
    group = options.group if options.group

    @ensureArray( where, group )

    type = 'plain'
    type = 'function' if typeof data == 'function'

    @contentArray[ group ][ where ].push
      'type': type
      data: data
      priority: priority

  getContentFor: ( where, options = { group: 'default' } ) ->
    group = options.group

    @ensureArray( where, group )

    content = ''
    priorityArray = Underscore.sortBy @contentArray[ group ][ where ],
      ( obj ) ->
        return obj.priority

    for aContent in priorityArray
      output = ''
      if aContent.type == 'plain'
        output = aContent.data
      else
        output = aContent.data()
      content += output
    content

class Arcabouco
  config              : {}

  Template            : false
  ContentGenerator    : false

  newRoutingAvaiable  : false
  controllerInstances : []
  routeToMethod       : []
  avaiableRoutes      : []

  _requestsCounter    : 0
  _requestsPolling    : 0
  requestsPerSecond   : 0
  _lastCPU            : {
    user: 0
    idle: 0
    sys: 0
    irq: 0
    nice: 0
  }

  constructor         : ( @config ) ->
    unless @config.baseDirectory
      console.log 'Configuration doesnt have baseDirectory directive'
      process.exit(1)

    global.objects = []

    @Template = new Template()
    @ContentGenerator = new ContentGenerator()

    #@content_for = @ContentGenerator.getContentFor

    @Template.loadTemplate Common.Path.normalize(__dirname + '/../templates/404.haml'), '404'
    @Template.loadTemplate Common.Path.normalize(__dirname + '/../templates/500.haml'), '500'

    setInterval =>
      # TODO: SEPARATE THIS INTO A CLASS
      @requestsPerSecond = @_requestsCounter
      @_requestsCounter = 0
      totalMemory = Common.Os.totalmem()
      freeMemory = Common.Os.freemem()
      loadAverage = Common.Os.loadavg()

      cpus = Common.Os.cpus()
      user = 0
      nice = 0
      sys = 0
      idle = 0
      irq = 0
      for cpu in cpus
        user += cpu.times.user
        nice += cpu.times.nice
        sys += cpu.times.sys
        idle += cpu.times.idle
        irq += cpu.times.irq
      total = user+nice+sys+idle+irq

      current_user = user-@_lastCPU.user
      current_nice = nice-@_lastCPU.nice
      current_sys = sys-@_lastCPU.sys
      current_idle = idle-@_lastCPU.idle
      current_irq = irq-@_lastCPU.irq
      current_total = current_user+current_nice+current_sys+current_idle+current_irq

      @_lastCPU.user = user
      @_lastCPU.nice = nice
      @_lastCPU.sys = sys
      @_lastCPU.idle = idle
      @_lastCPU.irq = irq
      @_lastCPU.total = user+nice+sys+idle+irq
#      console.log (current_user+current_nice+current_sys+current_irq) / current_total
#      console.log current_idle / current_total
    , 1000

  addRoutingToMethod : ( path, method, indexOfController ) ->
    @routeToMethod[ path ] =
      'method' : method
      'object' : indexOfController
    @newRoutingAvaiable = true
    path

  parseControllerRoutes : ( indexOfController ) ->
    ControllerObject = @controllerInstances[ indexOfController ]
    unless ControllerObject.getRoutes
      return false

    controllerRoutes = ControllerObject.getRoutes()
    for path of controllerRoutes
      @addRoutingToMethod path, controllerRoutes[ path ], indexOfController
  
  loadController      : ( controllerFilename ) ->
    unless controllerFilename.match(/\.js$/gi)
      false

    if controllerFilename.indexOf('.') == 0
      controllerFilename = @config.baseDirectory + controllerFilename.substring(1)

    ControllerObject = new (require controllerFilename)()
    ControllerObject.bootstrap( this ) if ControllerObject.bootstrap
    @parseControllerRoutes @controllerInstances.push(ControllerObject)-1

  work: ( ControllerObject ) ->

    instanceClass = new ControllerObject()
    if instanceClass.bootstrap or instanceClass.getRoutes
      ControllerObject = instanceClass
   
    ControllerObject.bootstrap( this ) if ControllerObject.bootstrap
    @parseControllerRoutes @controllerInstances.push(ControllerObject)-1

  assemble: ( directory ) ->
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
        if valid
          @work require file

  registerObject: ( objectName, object ) ->
    global.objects[ objectName ] = object
    true

  buildObject: (objectName) ->
    new (global.objects[ objectName ])

  getRawObjects: () ->
    global.objects

  contructRoutingForPattern : ( pattern ) ->
    params = []
    buildPattern = pattern.replace /\{(.*?)\}/g,
      ( match, sub1 ) ->
        params.push sub1
        return '([^\/]+)'
    buildPattern = buildPattern.replaceLast( '([^\/]+)', '([^$]+)' ) 
    constructedRoute =
      regex : new RegExp '^' + buildPattern + '$'
      params: params
      index : pattern

  buildRouting : ->
    orderedRouteNames = Underscore.keys( @routeToMethod ).sort().reverse()
    @avaiableRoutes = []
    for pattern in orderedRouteNames 
      @avaiableRoutes.push @contructRoutingForPattern( pattern )

  build: ->
    @buildRouting()

  parseRequest : ( request ) ->
    request.setEncoding 'utf-8'
    url = Common.Url.parse request.url, true
    request.documentRequested = url.pathname
    request.query = url.query

  parseLocaleFromRequest : ( request ) ->
    language = 'en'
    if @config.defaultLocale
      language = @config.defaultLocale
    if request.documentRequested.match /^\/(([a-z]{1,2})(\-[a-z]{1,2})?)($|\/)/ig
      requestedLocale = RegExp.$1
      request.documentRequested = request.documentRequested.replace '/' + requestedLocale, ''
    request.documentRequested = '/' if request.documentRequested == ''
    request.documentLocale = language

  buildParamsForRequest: ( route, args, otherParams ) ->
    params = {}
    for index of route.params
      params[ route.params[ index ] ] = args[ parseInt(index)+1 ]
    Underscore.extend( params, otherParams )
    params

  callMethodForRoute : ( route, params ) ->
    if @routeToMethod[ route.index ]
      ControllerIndex = @routeToMethod[ route.index ].object
      ControllerObject = @controllerInstances[ ControllerIndex ]
      ControllerObject[ @routeToMethod[ route.index ].method ]( params )
    else
      false

  respondWithError : ( respond ) ->
    respond.respondWith @Template.doRender( '500', this, {}, false ), 500

  respondWithTimeout: ( respond ) ->
    respond.respondWith @Template.doRender( '500', this, {}, false), 504

  respondWithNotFound: ( respond ) ->
    respond.respondWith @Template.doRender( '404', this, {}, false ), 404, 300

  dispatchRequest : ( request, response ) ->
    @parseRequest( request )
    @parseLocaleFromRequest( request )

    data = ''
    request.addListener 'data', ( data_chunk ) =>
      data += data_chunk

    request.addListener 'end', =>
      @_requestsCounter = @_requestsCounter+1
      hasRouted = false

      for route in @avaiableRoutes
        routeMatches = route.regex.exec( request.documentRequested )
        if routeMatches
          params = @buildParamsForRequest( route, routeMatches, {
            request  : request
            response : response
            route    : route.index
            app      : this
          })
          try        # Execute the method in a sandbox
            hasRouted = @callMethodForRoute( route, params ) unless hasRouted
          catch error
            @respondWithError response
            hasRouted = true
        
        if hasRouted
          break

      unless hasRouted
        @respondWithNotFound response

  createServer : ->
    Common.Http.createServer( @dispatchRequest.bind( this ) )

  createSecureServer: ( privateKey, certificate ) ->
    crypto = require 'crypto'
    credentials = crypto.createCredentials {
      key: privateKey
      cert: certificate
    }
    secureServer = Common.Http.createServer( @dispatchRequest.bind(this) )
    secureServer.setSecure( credentials )
    secureServer

module.exports = Arcabouco
