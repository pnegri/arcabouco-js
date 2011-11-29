#     Arcabouco.JS
#
#     (c) 2011 Patrick Negri, Yellers Software
#     Arcabouco.JS is freely distributable under the MIT license.
#     For all details and documentation:
#     http://github.com/pnegri/arcabouco-js

# Node.JS Monkey Patching for FS
# ------------------------------

# Include Commons
Common = require __dirname + '/common'

# ### readdirSyncR
#
# Extend Fs with a method to read a directory sync
Common.Fs.readdirSyncR = ( directory ) ->
  # Normalize the input directory
  directory = Common.Path.normalize directory
  # Get all files in the directory
  files = Common.Fs.readdirSync directory
  # Setup an array for valid files
  allFiles = []
  for file in files
    # Compute the full path of file
    fileWithPath = directory + '/' + file
    # Get information about the file
    stat = Common.Fs.statSync fileWithPath
    if stat.isFile()
      # If it is a file put in all files array
      allFiles.push fileWithPath
    if stat.isDirectory()
      # If it is a directory recursively call this method
      dirFiles = Common.Fs.readdirSyncR fileWithPath
      if dirFiles.length
        # Concatenate the results with files found previousily
        allFiles = allFiles.concat dirFiles
  allFiles
