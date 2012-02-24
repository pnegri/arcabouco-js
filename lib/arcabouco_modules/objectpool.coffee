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

      filename_prefix = ''
      filename_parts = object.split('/')
      if filename_parts.length > 1
        filename_prefix = filename_parts[ filename_parts.length - 3 ] + '.'

      @piecesArray.push
        filename: object
        filename_prefix: filename_prefix
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
    unless @objects[ object ]
      return false

    if @objects[ object ].instanceable
      return new @objects[ object ]['object']
    else
      return @objects[ object ]['object']

  build: (application, development=false) ->

    piecesByPriority = Common._.sortBy @piecesArray,
      ( obj ) ->
        return obj.priority

    outputDir = application.config.baseDirectory + '/cdn/js'

    console.log 'JS compilation started'

    c = 0
    buildReady = () ->
      c = c-1
      if c == 0
        console.log('JS generation ready')

    for pieceDetails in piecesByPriority
      pieceFilename = pieceDetails.filename
      pieceFilenamePrefix = pieceDetails.filename_prefix

      file_mtime = 0
      file_stats = Common.Fs.statSync( pieceFilename )
      if file_stats
        file_mtime = file_stats.mtime.getTime()

      baseFilename = Common.Path.basename( pieceFilename ) + '-' + file_mtime
      baseFilename = baseFilename.replace(".coffee","")
      baseFilename = baseFilename.replace(".js","")
      target_filename = "#{outputDir}/#{pieceFilenamePrefix}#{baseFilename}.js"

      file_exists = false

      try
        if Common.Fs.statSync( target_filename )
          file_exists = true
      catch e
        file_exists = false

      unless file_exists
        if pieceFilename.indexOf(".js")
          exec "cp #{pieceFilename} #{target_filename}"
        else if pieceFilename.indexOf(".coffee")
          exec "coffee --compile -p #{pieceFilename} > #{target_filename}.js", [], buildReady
        c = c+1

      application.Content.putContentFor 'head',
        "<script src=\"/cdn/js/#{pieceFilenamePrefix}#{baseFilename}.js\"></script>", { priority: pieceDetails.priority }

    if c == 0
      console.log 'JS generation ready'

module.exports = ArcaboucoObjectPool
