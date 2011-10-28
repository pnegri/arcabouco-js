// Arcabouco-JS is a Lightweight framework without garbage with i18n/mobile/html5 built-in support

var Common = require('./common');
require('./_monkey-patching.js'); // Yes - i know its ugly butttt...

var Arcabouco = function( config ) {
  this.config = config;

  // TODO: check for required directives
  if (!this.config.baseDirectory) {
    console.log('ERROR: Configuration doesnt have baseDirectory directive');
    process.exit(1);
  }

  //var files = Common.Fs.readdirSyncR( this.config.baseDirectory );
  //console.log(files);
}

Arcabouco.prototype = {
  i18n: require('i18n'),
  config: {},
  httpServer: null,
  routes: [],
  controllerRoutes: [],
  controllerIndexes: [],
  controllerInstances: [],
  mountApplication: null,
  _routingChanged: false,
  loadController:
    function( controller_filename ) {
      if (!controller_filename.match(/\.js$/gi)) return;

      var this_controller = require( controller_filename );
      var controller_index = this.controllerInstances.push( this_controller );

      if (this_controller.bootstrap != undefined) this_controller.bootstrap( this );

      if (this_controller.getRoutes == undefined) return;
      var controller_routes = this_controller.getRoutes();

      for (var route_path in controller_routes) {
        this.controllerIndexes[ route_path ] = {
          'method' : controller_routes[ route_path ],
          'object' : controller_index-1
        }
        this.controllerRoutes.push( route_path );
        this._routingChanged = true;
      }
    },
  buildRouting:
    function() {
      var sorted_cr = this.controllerRoutes.sort().reverse();
      this.routes = [];

      for (var index in sorted_cr) {
        var pattern = sorted_cr[ index ];
        var params = [];

        var result = pattern.replace(/\{(.*?)\}/g,
          function( match, sub1, pos, whole ) {
            params.push( sub1 );
            return "([^\/]+?)";
          }
        );

        result = '^' + result + "(\\/?\$|\\/?\\?.*$)";

        this.routes.push( {
          regex  : ( new RegExp( result ) ),
          params : params,
          index  : pattern
        });
      }

      if (global.debugging) {
        console.log( 'DEBUG: Build routing array:' );
        console.log( this.routes );
      }
    },
  dispatchRequest:
    function( request, response ) {
      request.setEncoding( 'utf-8' );

      var data = '';
      var url = Common.Url.parse( request.url, true );
      var path_name = url.pathname;
      var query = url.query;

      path_name = path_name.replace(/\/$g/,'');
      if (path_name == '') path_name = '/';

      if (global.debugging) {
        console.log('DEBUG: HTTP Request: ' + path_name);
      }

      request.addListener('data',
        function onData( data_chunk ) {
          data += data_chunk;
        }
      );

      // Methods PlaceHolder
      response.respondWith = null;
      response.redirectTo = null;
      response.respondError = null;

      request.addListener('end',
        function onRequest() {
          var url_parts = null;
          for (index in this.routes) {
            var route = this.routes[ index ];
            path_name.replace( route.regex,
              function matchRoute( match ) {
                url_parts = {};
                for (var i=0; i<route.params.length; i++) url_parts[ route.params[i] ] = arguments[i+1];
                url_parts.response = response;
                url_parts.query = query;
                url_parts.path_name = path_name;
                url_parts.data = data;
                url_parts.route = route.index;
                url_parts.request = request;
                url_parts.app = this;
              }
            );
            if (url_parts) break;
          }

          var routed = false;

          // Try? echo Robot?
          // Error Handling Here
          if (url_parts) {
            var controller_index = this.controllerIndexes[ url_parts.route ];
            var controller = this.controllerInstances[ controller_index.object ];
            if ( (controller[ controller_index.method ] != undefined) && (controller[ controller_index.method]( url_parts )) ); routed = true;
          }

          if (!url_parts || !routed) {
            // Response with Template system a 404
            response.writeHead( 404, {"Content-Type":"text/plain"});
            response.write("404 Not Found.");
            response.end();
          }
        }.bind(this)
      );
    },
  run:
    function() {
      this.createServer( 8888 );
    },
  createServer:
    function( serverPort ) {
      this.httpServer = Common.Http.createServer( this.dispatchRequest.bind(this) ).listen( serverPort );
      return this.httpServer;
    }
};

module.exports = Arcabouco;
