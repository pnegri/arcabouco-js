var Http = require('http');
var FS = require('fs');
var Path = require('path');

function LanguageHelper()
{
}

LanguageHelper.getAvaiableLanguages = function()
{
  return I18N.aLanguages.names;
}

LanguageHelper.getLanguageLocale = function( sLanguage )
{
  return I18N.aLanguages.locales[ I18N.aLanguages.names.indexOf( sLanguage ) ];
}

LanguageHelper.getLocalizedURI = function( sBaseURI, sURI, sLocale )
{
  if (sLocale == 'en') sLocale = '';
  
  var sLocalizedURI = sLocale + '/' + sURI;
  sLocalizedURI = sLocalizedURI.replace( '//', '/' );
  sLocalizedURI = sLocalizedURI.replace( /^\//, "" );
  return sBaseURI + '/' + sLocalizedURI;
}

module.exports = LanguageHelper;
