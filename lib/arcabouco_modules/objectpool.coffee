Common = require __dirname + '/../common'
require __dirname + '/../_monkey-patching'
{spawn, exec} = require 'child_process'

class ArcaboucoObjectPool
  piecesArray         : []
  objects             : []

  registerObject: ( pieceFilename, options ) ->
    priority = 0
    priority = options.priority if options.priority

    @piecesArray.push
      filename: pieceFilename
      priority: priority

  build: (application, development=false) ->

    piecesByPriority = Common._.sortBy @piecesArray,
      ( obj ) ->
        return obj.priority

    outputDir = application.config.baseDirectory + '/cdn/js'

    c = 0
    for pieceDetails in piecesByPriority
      pieceFilename = pieceDetails.filename
      
      baseFilename = Common.Path.basename( pieceFilename, '.coffee' ) + '-' + c

      exec "coffee --compile -p #{pieceFilename} > #{outputDir}/#{baseFilename}.js"

      application.Content.putContentFor 'head',
        "<script src=\"/cdn/js/#{baseFilename}.js\"></script>", { priority: pieceDetails.priority }

      c = c+1

module.exports = ArcaboucoObjectPool
