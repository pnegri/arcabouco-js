/**
*  Lets Yell Server
*/

var SERVER_VERSION = '0.1 Pre-Alpha';
var SERVER_NAME = 'Lets Yell - Version: ' + SERVER_VERSION;

console.log(SERVER_NAME);
console.log('loading...');

// Load required modules
var gmHttp = require('http');
var gmFS = require('fs');
var gmUrl = require('url');
var gmOAP = require(__dirname + '/lib/oauth_provider');

// Loaded in Global Javascript Space
global.I18N = require('i18n');
global.App = require(__dirname + '/configuration');
global.Helper = require(__dirname + '/lib/helper');
global.Template = require(__dirname + '/lib/template');
global.OAuth = require('oauth').OAuth;

// Output Debugging Information
global.bDebugging = true;

// If we are using Airbrake for Exceptions
if (App.bUseAirbrake) {
  console.log('Using Airbrake for Exception');
  global.Airbrake = require('airbrake').createClient(App.sAirbrakeAPI);
  global.Airbrake.host = App.sBaseURI;
  global.Airbrake.env = App.sEnv;
  Airbrake.handleExceptions();
}

I18N.aLanguages = {
  locales: ['en', 'pt-BR' ],
  names: ['English', 'Portugues' ]
}

I18N.configure({
    // setup some locales - other locales default to en silently
    locales:I18N.aLanguages.locales,
    // where to register __() and __n() to, might be "global" if you know what you are doing
    register: global
});

var gmDispatcher = require('./lib/dispatcher');

// Create a server with the dispatcher module as callback for requests
var mServer = gmHttp.createServer(gmDispatcher.dispatchRequest).listen(8888);

console.log('Waiting for requests...');
