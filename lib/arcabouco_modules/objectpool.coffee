Common = require __dirname + '/../common'
require __dirname + '/../_monkey-patching'
{spawn, exec} = require 'child_process'

class ArcaboucoObjectPool
  piecesArray         : []
  objects             : []

  registerObject: ( object, options = {} ) ->
    priority = 0
    priority = options.priority if options.priority

    remote = false
    remote = options.remote if options.remote

    name = ""
    name = options.name if options.name

    # TODO: Object Register must detect if its a file or object
    if remote or (typeof(object) == "string")
      @piecesArray.push
        filename: object
        priority: priority
    else
      ArcaboucoObject = object
      isInstanceable = false
      try
        instanceObject = new ArcaboucoObject()
        if instanceObject.isObject
          isInstanceable = true

      @objects[ name ] = (
        object: object
        instanceable: isInstanceable
      )

  getObject: ( object ) ->
    return false unless @objects[ object ]

    if @objects[ object ].instanceable
      return new @objects[ object ]['object']
    else
      return @objects[ object ]['object']

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
