Common = require __dirname + '/../common'

class ArcaboucoRequest
  routeToMethod: []
  avaiableRoutes: []
  newRoutingAvaiable: false

  addRoutingToMethod: ( path, method, indexOfController ) ->
    @routeToMethod[ path ] =
      'method' : method
      'object' : indexOfController
    @newRoutingAvaiable = true
    path

  parseRoutes: ( index, Application ) ->
    ControllerObject = Application.Controller.get( index )
    unless ControllerObject.getRoutes
      return false

    controllerRoutes = ControllerObject.getRoutes()
    for path of controllerRoutes
      @addRoutingToMethod path, controllerRoutes[ path ], index

  constructRoutingForPattern : ( pattern ) ->
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

  rebuildRoutes: ->
    orderedRouteNames = Common._.keys( @routeToMethod ).sort().reverse()
    @avaiableRoutes = []
    for pattern in orderedRouteNames
      @avaiableRoutes.push @constructRoutingForPattern( pattern )

  callMethodForRoute : ( route, params, Controller ) ->
    if @routeToMethod[ route.index ]
      ControllerIndex = @routeToMethod[ route.index ].object
      ControllerObject = Controller.get ControllerIndex
      ControllerObject[ @routeToMethod[ route.index ].method ]( params )
    else
      false

  parseRequest : ( request ) ->
    request.setEncoding 'utf-8'
    url = Common.Url.parse request.url, true
    request.documentRequested = url.pathname
    request.query = url.query

  buildParamsForRequest: ( route, args, otherParams ) ->
    params = {}
    for index of route.params
      params[ route.params[ index ] ] = args[ parseInt(index)+1 ]
    Common._.extend( params, otherParams )
    params


  dispatch: ( request, response ) ->
    
    if @newRoutingAvaiable
      @rebuildRoutes()
      @newRoutingAvaiable = false

    data = ''
    request.addListener 'data', ( data_chunk ) =>
      data += data_chunk

    @parseRequest( request )

    request.addListener 'end', =>

      hasRouted = false

      for route in @avaiableRoutes
        routeMatches = route.regex.exec( request.documentRequested )
        if routeMatches
          params = @buildParamsForRequest( route, routeMatches, {
            request  : request
            response : response
            route    : route.index
            app      : response.application
          })
          try        # Execute the method in a sandbox
            hasRouted = @callMethodForRoute( route, params, request.application.Controller ) unless hasRouted
          catch error
            response.respondWithError()
            hasRouted = true
        
        if hasRouted
          break

      unless hasRouted
        response.respondWithNotFound()

module.exports = ArcaboucoRequest
