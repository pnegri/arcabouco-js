#     Arcabouco.JS
#
#     (c) 2011 Patrick Negri, Yellers Software
#     Arcabouco.JS is freely distributable under the MIT license.
#     For all details and documentation:
#     http://github.com/pnegri/arcabouco-js

# Node.JS Monkey Patching
# -----------------------

# Include Commons
Common = require __dirname + '/common'

require __dirname + '/_monkey-fs.coffee'

# ### replaceLast
#
# Extend String with a replaceLast method
String.prototype.replaceLast = ( search, replace ) ->
  string = this
  n = string.lastIndexOf( search )
  if n >= 0 && n + replace.length >= string.length
    string = string.substring(0, n) + replace
  string

# Extending and Patching HTTP
# ---------------------------

# ### Response Grouping
#
# Include a 'group' in response
Common.Http.ServerResponse.prototype.group = 'default'

Common.Http.ServerResponse.prototype.getGroup = () ->
  @group

Common.Http.ServerResponse.prototype.setGroup = ( groupName ) ->
  @group = groupName

# ### Response Redirection
Common.Http.ServerResponse.prototype.redirectTo = ( url ) ->
  @writeHead 302, { 'Location': url }
  @end()

# ### respondWith
#
# Extend Response with a cache-corrected responder

Common.Http.ServerResponse.prototype.respondWith = ( content, options = {} ) ->
 
  # Configure default response options
  response_option = {}
  response_option.type = if options.type then options.type else 'text/html'
  response_option.expiration = if options.expiration then options.expiration else 0
  response_option.status = if options.status then options.status else 200
  response_option.charset = if options.charset then options.charset else 'utf-8'

  # Calculate the expiration
  expirationTime = new Date()
  headers =
    'Content-Type': response_option.type + '; charset=' + response_option.charset
  if response_option.expiration > 0
    expirationTime.setTime expirationTime.getTime() + response_option.expiration
    Common._.extend headers,
      'Cache-Control' : 'max-age=' + response_option.expiration + ', public, most-revalidate'
      'Expires'       : expirationTime.toGMTString()
  else
    Common._.extend headers,
      'Cache-Control' : 'max-age=0, no-cache, no-store, must-revalidate'
      'Pragma'        : 'no-cache'
      'Expires'       : 'Thu, 01 Jan 1970 00:00:00 GMT'
  @writeHead response_option.status, headers
  @write content
  @end()

Common.Http.ServerResponse.prototype.respondWithError = () ->
  return false unless @application
  @respondWith @application.render( '500', this, {}, '' )

Common.Http.ServerResponse.prototype.respondWithNotFound = () ->
  return false unless @application
  @respondWith @application.render( '404', this, {}, '' )
