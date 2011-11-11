require 'coffee-script'
Common = require __dirname + '/common'
require __dirname + '/_monkey-fs'
Underscore = require 'underscore'

String.prototype.replaceLast = ( search, replace ) ->
  string = this
  n = string.lastIndexOf( search )
  if n >= 0 && n + replace.length >= string.length
    string = string.substring(0, n) + replace
  string

Common.Http.ServerResponse.prototype.group = 'default'

Common.Http.ServerResponse.prototype.getGroup = () ->
  @group

Common.Http.ServerResponse.prototype.setGroup = ( groupName ) ->
  @group = groupName

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
