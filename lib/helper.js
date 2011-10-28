/**
*  Helper - Utility Libray
*/

var gmHttp = require('http');
var gmFS = require('fs');
var gmPath = require('path');

/**
*  Core Class - Constructor
*/
function Helper()
{
}

/**
*  dateFromString - Convert a string with format YYYYMMDDHHmmss to a valid Javascript Date Object
*/
Helper.dateFromString = function(sTmp)
{
  // String format must be YYYYMMDDHHmmss
  // TODO: Thrown exception if string is invalid
  var nYear = parseInt(sTmp.substring(0,4));
  var nMonth = parseInt(sTmp.substring(4,6))-1;
  var nDay = parseInt(sTmp.substring(6,8));
  var nHour = parseInt(sTmp.substring(8,10));
  var nMin = parseInt(sTmp.substring(10,12));
  var nSec = parseInt(sTmp.substring(12));
  return new Date(nYear,nMonth,nDay,nHour,nMin,nSec);
}

Helper.dateToEpoch = function(oDate)
{
  return parseInt(Date.UTC(oDate.getUTCFullYear(),oDate.getUTCMonth(),oDate.getUTCDate(),oDate.getUTCHours(),oDate.getUTCMinutes(),oDate.getUTCSeconds(),oDate.getUTCMilliseconds())/1000);
}

Helper.urlToTiny = function(sUrl, oCallBack)
{
  var oTiny = gmHttp.createClient(80, 'tinyurl.com');
  var oReq = oTiny.request('GET','/api-create.php?url=' + encodeURIComponent(sUrl), {'host': 'tinyurl.com'} );
  oReq.end();
  oReq.on('response', function(oResp) {
    oResp.setEncoding('utf8');
    sData = '';
    oResp.on('data', function(sChunk) { sData += sChunk; });
    oResp.on('end', function() {
      if (oResp.statusCode != 200) sData = null;
      oCallBack( sData );
    });
  });
}

Helper.readdirSync = function( sDirectory ) {
  sDirectory = gmPath.normalize(sDirectory);
  var aFiles = gmFS.readdirSync(sDirectory);
  var aAllFiles = new Array();
  for (nIndex in aFiles) {
    var sFile = aFiles[nIndex];
    var oStat = gmFS.statSync( sDirectory + '/' + sFile );
    if (oStat.isFile()) {
      aAllFiles.push( sDirectory + '/' + sFile );
    }
    if (oStat.isDirectory()) {
      var aDirFiles = Helper.readdirSync( sDirectory + '/' + sFile );
      if (aDirFiles.length) aAllFiles = aAllFiles.concat(aDirFiles); 
    }
  };

  return aAllFiles;
}

Helper.getBaseURI = function()
{
  var sBaseURI = App.sBaseURI;
  var sLanguage = I18N.getLocale();
  if (sLanguage == 'en') sLanguage = '';
  if (sLanguage != '') sBaseURI += '/' + sLanguage;
  return sBaseURI;
}

module.exports = Helper;
