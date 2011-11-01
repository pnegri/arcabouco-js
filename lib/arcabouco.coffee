Common = require './common'
Underscore = require 'underscore'
require './_monkey-patching.js'

#Common.Http.ServerResponse.prototype.testing = 'BlaBleBli'

class Arcabouco
  config              : {}
  newRoutingAvaiable  : false
  controllerInstances : []
  routeToMethod       : []
  avaiableRoutes      : []

  constructor         : ( @config ) ->
    unless @config.baseDirectory
      console.log 'Configuration doesnt have baseDirectory directive'
      process.exit(1)

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
        return '([^\/]+?)'
    constructedRoute =
      regex : new RegExp '^' + buildPattern + '(\\/?\$|\\/?\\?.*$)'
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

  dispatchRequest : ( request, response ) ->
    @parseRequest( request )
    @parseLocaleFromRequest( request )

    data = ''
    request.addListener 'data', ( data_chunk ) =>
      data += data_chunk

    request.addListener 'end', =>
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
            # Call Bad Robot - Error 500
            hasRouted = true
        
        if hasRouted
          break

      # Replace with response.respondWithPageNotFound()
      unless hasRouted
        response.writeHead( 404, {'Content-Type':'text/plain'} )
        response.write('404 not found')
        response.end()

  createServer : ( serverPort ) ->
    testServer = Common.Http.createServer( @dispatchRequest.bind( this ) )
    testServer.listen( serverPort )
#    testServer.close()
    testServer

module.exports = Arcabouco
