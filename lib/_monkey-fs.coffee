Common = require __dirname + '/common'

Common.Fs.readdirSyncR = ( directory ) ->
  directory = Common.Path.normalize directory
  files = Common.Fs.readdirSync directory
  allFiles = []
  for file in files
    fileWithPath = directory + '/' + file
    stat = Common.Fs.statSync fileWithPath
    if stat.isFile()
      allFiles.push fileWithPath
    if stat.isDirectory()
      dirFiles = Common.Fs.readdirSyncR fileWithPath
      if dirFiles.length
        allFiles = allFiles.concat dirFiles
  allFiles
