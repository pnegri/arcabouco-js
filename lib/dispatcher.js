// TODO: Dispatcher Request must be initialized by directory... not by __dirname

/**
*  Dispatcher - Classe para delegacao e disparo de pedidos
*/

// Load Modules
var gmHttp = require('http');
var gmFS = require('fs');
var gmUrl = require('url');
var gmHelper = require( __dirname + '/helper');

// Prepare a set of arrays to deal with controllers
//    1. Get all files from ../controllers
//    2. Load these modules into gaControllers array
//    3. Call a getRoutes if this method exist in controller
//    4. Use the returned routes and transform it into a valid Perl Regular Expression
//    5. Construct a function call and also store the Param name defined in getRoutes to use in 
//       request delegator (The method will receive the parsed params with correct param name)
var gaControllers = new Array();
var gaControllersFile = gmHelper.readdirSync( __dirname + "/../controllers" );
var gaRoutes = new Array();
var gaObjectRoutes = new Array();

// For all files found at ../api
for (var nIndex in gaControllersFile)
{
  // Load only JS files
  if (!gaControllersFile[nIndex].match(/\.js$/gi)) continue;

  // Load the Module
  var oNewController = require(gaControllersFile[nIndex]);
  // Push into array and remember the index
  var nControllerIndex = gaControllers.push( oNewController );

  // Get all routes from module if exist
  if (oNewController.getRoutes == undefined) continue;
  var aThisRoutes = oNewController.getRoutes();
  
  // For each route string in all returned routes from this module/controller
  for (var sOneRoute in aThisRoutes)
  {
    // Store the information about this particular route and method, also which index the object is on Controllers array
    gaObjectRoutes[ sOneRoute ] = { 
      'method' : aThisRoutes[sOneRoute],
      'object' : nControllerIndex-1
    }
    // Push the route pattern, so we can order to find it using Regular Expressions
    gaRoutes.push( sOneRoute  );
  }
}

// Reverse sort the routes, so big routes get resolved first
var gaSortedRoutes = gaRoutes.sort().reverse();
gaRoutes = new Array();

// Almost done, now we need to get these routes, and convert then to a valid Regular Expression and store the param names to dispatcher
for (var sIndex in gaSortedRoutes)
{
  var sPattern = gaSortedRoutes[sIndex];    // The Route Pattern
  var aParams = [];

  // With this pattern, convert it to a valid regular expression, and use the names inside route brackets (Ex: /yells/{number}/ ) to
  // create a params array
  var sResult = sPattern.replace(/\{(.*?)\}/g, function(match, sub1, pos, whole) {
    aParams.push(sub1);
    return "([^\/]+?)";
  });

  // Construct the final Perl Regular Expression
  sResult = "^" + sResult + "(\\/?\$|\\/?\\?.*$)";

  // Store our route information:
  //  oRegex : the regex to check if incoming request can be matched with this controller
  //  oParams : the name of the params that we will extract from the request URI
  //  sIndex  : the index of the controller on our oController Array
  gaRoutes.push( {
    oRegex : (new RegExp(sResult) ),
    aParams: aParams,
    sIndex: sPattern
  } );
}

function respondWith ( sContent, sType, nStatus, nExpiration )
{
  sType = (!sType)?'text/html':sType;
  nStatus = (!nStatus)?200:nStatus;
  nExpiration = (!nExpiration)?0:nExpiration;

  var oExpirationTime = new Date();

  var aHeaders = {}

  if (nExpiration > 0) {
    oExpirationTime.setTime( oExpirationTime.getTime() + nExpiration );
    aHeaders = {
      'Content-Type':'text/html; charset=utf-8',
      'Cache-Control': 'max-age=' + nExpiration + ', public, most-revalidate',
      'Expires': oExpirationTime.toGMTString()
    }
  }
  else
  {
    aHeaders = {
      'Content-Type':'text/html; charset=utf-8',
      'Cache-Control': 'max-age=0, no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': 'Thu, 01 Jan 1970 00:00:00 GMT'
    }
  }

  this.writeHead( nStatus, aHeaders );
  this.write( sContent );
  this.end();

  return true;
}

function redirectTo ( sURL )
{
  this.writeHead( 302, { 'Location': sURL } );
  this.end();
}

function doError()
{
  this.respondWith( Template.doRender('badapp.haml', this, {}, 'blank.haml' ), 500 );
}

/**
*  dispatchRequest - Get the request and delegate it to some controller
*/
function dispatchRequest(mRequest, mResponse)
{
  // Set the character encoding to a universal format
  mRequest.setEncoding('utf-8');

  var sData = '';
  var oUrl = gmUrl.parse(mRequest.url,true); // Parses the Request URI
  var sPathName = oUrl.pathname;             // The Route Address
  var aQuery = oUrl.query;                   // The Query Params

  /*
  // Parse Accept Language
  var sLanguage = mRequest.headers['accept-language'];

  // Create a Supported Client Side Language Array
  var aLanguages = new Array();
  var aMatches = sLanguage.match(/([a-z]{1,8}(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|0\.[0-9]+))?/ig);
  for (nIndex in aMatches) {
    var aPart = aMatches[nIndex].split(';');
    var sLanguagePart = aPart[0];
    var aLanguageParts = sLanguagePart.split('-');
    var sLanguage = aLanguageParts[0];
    if (aLanguageParts.length > 1) sLanguage += '-' + aLanguageParts[1].toUpperCase();
    // Append the new Language
    aLanguages.push( sLanguage );
  }
  */

  //I18N.setLocale( aLanguages[0] );
  I18N.setLocale( 'en' );

  //if (sPathName.match(/([a-z]{
  //
  // Trim all '/'
  sPathName = sPathName.replace(/\/$/g,"");

  if (sPathName.match(/^\/(([a-z]{1,2})(\-[a-z]{1,2})?)($|\/)/ig)) {
    var sLanguage = RegExp.$1;
    sPathName = sPathName.replace('/' + sLanguage,'');
    I18N.setLocale( sLanguage );
  }

  if (sPathName == '') sPathName = "/"; // If empty, make it a default call '/'

  console.log(sPathName);

  // Add data to a array if we are receiving
  mRequest.addListener('data', function(sDataChunk)
  {
    sData += sDataChunk;
  });

  mResponse.respondWith = respondWith;
  mResponse.redirectTo = redirectTo;
  mResponse.respondError = doError;

  // At End of Request, process all data
  mRequest.addListener( 'end', function() {

    // Using Regular Expressions, iterate in our Routes Array (gaRoutes) and find if any controller
    // can respond to this request
    var aUrlParts = null;
    for (var nRoute in gaRoutes)
    {
      var oRoute = gaRoutes[ nRoute ];
      sPathName.replace( oRoute.oRegex, function(sMatch) {
        // If it can respond, then populate the aUrlParts (which will erase its null state)
        aUrlParts = {};
        var i=0;
        for (; i<oRoute.aParams.length; i++)
        {
          aUrlParts[ oRoute.aParams[i] ] = arguments[i+1]; // Convert the request params extracted from URI
        }
        // Add pointers to any object controller might need
        aUrlParts.mResponse = mResponse;
        aUrlParts.aQuery = aQuery;
        aUrlParts.sPathName = sPathName;
        aUrlParts.sData = sData;
        aUrlParts.sRoute = oRoute.sIndex;
        aUrlParts.mRequest = mRequest;
        //aUrlParts.aSupportedLanguages = aLanguages;
      });
      if (aUrlParts) break; // If we have a winner, stop
    }

    var bRouted = false; // Is URI routed?

    if (aUrlParts) {
      var oObjectRoute = gaObjectRoutes[ aUrlParts.sRoute ]; // Find the information about the object dispatcher
      var oController = gaControllers[ oObjectRoute.object ]; // Find the Module
      if ( (oController[ oObjectRoute.method ] != undefined ) && (oController[ oObjectRoute.method]( aUrlParts ))) bRouted = true; // URI was routed
    }

    // If not routed, display the internal 404
    if (!aUrlParts || !bRouted) {
      mResponse.writeHead(404, {"Content-Type":"text/plain"});
      mResponse.write("404 Not Found.");
      mResponse.end();
    }

  });
}

exports.dispatchRequest = dispatchRequest;
