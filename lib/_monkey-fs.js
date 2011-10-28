Common.Fs.readdirSyncR = function( directory ) {
  directory = Common.Path.normalize( directory );
  var files = Common.Fs.readdirSync( directory );
  var allFiles = new Array();
  for (nIndex in files) {
    var file = files[ nIndex ];
    var stat = Common.Fs.statSync( directory + '/' + file );
    if (stat.isFile()) allFiles.push( directory + '/' + file );
    if (stat.isDirectory()) {
      var dirFiles = Common.Fs.readdirSyncR( directory + '/' + file );
      if (dirFiles.length) allFiles.concat( dirFiles );
    }
  }

  return allFiles;
}
