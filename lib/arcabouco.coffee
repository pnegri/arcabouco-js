Common = require './common'
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
    return false unless ControllerObject.getRoutes

    controllerRoutes = ControllerObject.getRoutes()
    for path of controllerRoutes
      method = controllerRoutes[ path ]
      @addRoutingToMethod path, method, indexOfController
  
  loadController      : ( controllerFilename ) ->
    unless controllerFilename.match(/\.js$/gi)
      false

    ControllerObject = require controllerFilename
    ControllerObject.bootstrap( this ) if ControllerObject.bootstrap
    @parseControllerRoutes @controllerInstances.push(ControllerObject)-1

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
    routeToMethod = @routeToMethod.sort().reverse()
    @avaiableRoutes = []
    for pattern of routeToMethod
      @avaiableRoutes.push @contructRoutingForPattern( pattern )
    if global.debugging
      console.log 'DEBUG: buildRouting'
      console.log @avaiableRoutes
    true

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
    for paramName of otherParams
      params[ paramName ] = otherParams[ paramName ]
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
        # TODO, see if we can use exec to better readability
        request.documentRequested.replace( route.regex,
          ( match ) =>
            params = @buildParamsForRequest( route, arguments, {
              request: request
              response: response
              route: route.index
              app: this
            })
            hasRouted = @callMethodForRoute( route, params )
        )
        
        if hasRouted
          break

      # Replace with response.respondWithPageNotFound()
      unless hasRouted
        response.writeHead( 404, {'Content-Type':'text/plain'} )
        response.write('404 not found')
        response.end()

  createServer : ( serverPort ) ->
    Common.Http.createServer( @dispatchRequest.bind( this ) ).listen( serverPort )

module.exports = Arcabouco
