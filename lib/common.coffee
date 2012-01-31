#     Arcabouco.JS
#
#     (c) 2011 Patrick Negri, Yellers Software
#     Underscore is freely distributable under the MIT license.
#     For all details and documentation:
#     http://github.com/pnegri/arcabouco-js

# Common Modules
# --------------

# Include a list of common used modules, keeping it all in one place
Common =
  Os   : require 'os'
  Http : require 'http'
  Fs   : require 'fs'
  Path : require 'path'
  Url  : require 'url'
  Query: require 'querystring'
  Crypt: require 'crypto'
  _    : require 'underscore'     # Enable Underscore Library using Common._

module.exports = Common
