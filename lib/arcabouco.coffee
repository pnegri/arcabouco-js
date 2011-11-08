Common = require __dirname + '/common'
Underscore = require 'underscore'
require __dirname + '/_monkey-patching'

Haml = require 'haml'
#Common.Http.ServerResponse.prototype.testing = 'BlaBleBli'


Common.Http.ServerResponse.prototype.redirectTo = ( url ) ->
  @writeHead 302, { 'Location': url }
  @end()

Common.Http.ServerResponse.prototype.respondWith = ( content, type='text/html', status=200, expiration=0 ) ->
  expirationTime = new Date()
  headers = 
    'Content-Type': type + '; charset=utf-8'
  if expiration > 0
    expirationTime.setTime expirationTime.getTime() + expiration
    Underscore.extend headers,
      'Cache-Control' : 'max-age=' + expiration + ', public, most-revalidate'
      'Expires'       : expirationTime.toGMTString()
  else
    Underscore.extend headers,
      'Cache-Control' : 'max-age=0, no-cache, no-store, must-revalidate'
      'Pragma'        : 'no-cache'
      'Expires'       : 'Thu, 01 Jan 1970 00:00:00 GMT'
  @writeHead status, headers
  @write content
  @end()

Template =
  loadedTemplates : []
  getTemplate: ( templateFile ) ->
    templateFile = Common.Path.basename templateFile
    unless @loadedTemplates[ templateFile ]
      return false
    @loadedTemplates[ templateFile ]
  loadTemplate: ( templateFile ) ->
    unless templateFile
      return false
    unless templateFile.match /\.haml$/gi
      return false
    baseTemplateFile = Common.Path.basename templateFile 
    template = Common.Fs.readFileSync templateFile, 'utf-8'
    compiledTemplate = Haml.compile template
    optimizedTemplate = Haml.optimize compiledTemplate
    @loadedTemplates[ baseTemplateFile ] = optimizedTemplate

  doRender: ( templateFile, context, params, layout = 'layout.haml' ) ->
    template = @getTemplate templateFile
    unless template
      return false
    content = Haml.execute template, context, params
    if layout
      params.content = content
      return Haml.execute layout, context, params
    return content

class Arcabouco
  config              : {}

  Template            : Template

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

    @Template.loadTemplate Common.Path.normalize (__dirname + '/../views/404.haml')
    @Template.loadTemplate Common.Path.normalize (__dirname + '/../views/500.haml')

    setInterval =>
      @requestsPerSecond = @_requestsCounter
      @_requestsCounter = 0
#      console.log 'Requests per Second: ' + @requestsPerSecond
#      console.log 'Mem: ' + Common.Os.totalmem() + ' / ' + Common.Os.freemem()
#      console.log 'Load AVG: '
#      console.log Common.Os.loadavg()
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

#      console.log Common.Os.cpus()
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

    ControllerObject = require controllerFilename
    ControllerObject.bootstrap( this ) if ControllerObject.bootstrap
    @parseControllerRoutes @controllerInstances.push(ControllerObject)-1

  mountApplication : ( application ) ->
    console.log 'App Place Holder'

#  mountApplicationWithObject
#  mountApplicationWithFile

  contructRoutingForPattern : ( pattern ) ->
    params = []
    buildPattern = pattern.replace /\{(.*?)\}/g,
      ( match, sub1 ) ->
        params.push sub1
        return '([^\/]+)'
    replacer = '([^\/]+)'
    n = buildPattern.lastIndexOf( replacer )
    if n >= 0 && n + replacer.length >= buildPattern.length
      buildPattern = buildPattern.substring(0, n) + "([^$]+)";
    constructedRoute =
      regex : new RegExp '^' + buildPattern
      params: params
      index : pattern

  buildRouting : ->
    orderedRouteNames = Underscore.keys( @routeToMethod ).sort().reverse()
    @avaiableRoutes = []
    for pattern in orderedRouteNames 
      @avaiableRoutes.push @contructRoutingForPattern( pattern )

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
    respond.respondWith @Template.doRender( '500.haml', this, {}, false ), 500

  respondWithTimeout: ( respond ) ->
    respond.respondWith @Template.doRender( '500.haml', this, {}, false), 504

  respondWithNotFound: ( respond ) ->
    respond.respondWith @Template.doRender( '404.haml', this, {}, false ), 404, 300

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

      # Replace with response.respondWithPageNotFound()
      unless hasRouted
        @respondWithNotFound response

  createServer : ( serverPort ) ->
    testServer = Common.Http.createServer( @dispatchRequest.bind( this ) )
    testServer.listen( serverPort )
#    testServer.close()
    testServer

module.exports = Arcabouco
