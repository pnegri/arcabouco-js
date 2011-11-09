require 'coffee-script'
Common = require __dirname + '/common'
require __dirname + '/_monkey-fs'

String.prototype.replaceLast = ( search, replace ) ->
  string = this
  n = string.lastIndexOf( search )
  if n >= 0 && n + replace.length >= string.length
    string = string.substring(0, n) + replace
  string
