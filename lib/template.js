var gmConfiguration = require('../configuration.js');
var gmHelper = require( __dirname + '/helper' );
var gmPath = require('path');
var gmFS = require('fs');
var gmHaml = require( __dirname + '/haml' );

global.LanguageHelper = require( __dirname + '/language_helper' );

var sBasePath = gmPath.normalize( __dirname + '/../' );

var gaTemplates = new Array();
var gaTemplateFiles = gmHelper.readdirSync( __dirname + "/../views" );

//console.log('Compiling templates:');
for (var nIndex in gaTemplateFiles)
{
  if (!gaTemplateFiles[nIndex].match(/\.haml$/gi)) continue;

  var sTemplateFile = gaTemplateFiles[nIndex].replace( sBasePath + 'views/', '' );

  var sTemplate = gmFS.readFileSync( gaTemplateFiles[nIndex], 'utf-8');
  var sCompiledTemplate = gmHaml.compile( sTemplate );
  var sOptimizedTemplate = gmHaml.optimize( sCompiledTemplate );

  gaTemplates[ sTemplateFile ] = sOptimizedTemplate;
  //console.log(' - ' + sTemplateFile + ' => OK');
}

function Template()
{
}

Template.getTemplate = function(sTemplateName)
{
  if (gaTemplates[ sTemplateName ] == undefined) return false;
  return gaTemplates[ sTemplateName ];
}

Template.configureParams = function(aParams)
{
  if (!aParams.sTitle) aParams.sTitle = 'App Default Title';
  return aParams;
}

Template.doRender = function(sTemplateName, oCurrent, aParams, sDefaultLayout)
{
  sDefaultLayout= (!sDefaultLayout)?'layout.haml':sDefaultLayout;
  if (gaTemplates[ sTemplateName ] == undefined) return false;

  aParams = Template.configureParams( aParams );

  var sContent = gmHaml.execute( gaTemplates[ sTemplateName ], oCurrent, aParams);

  if (gaTemplates[ sDefaultLayout ] && (sDefaultLayout != false) ) {
    aParams.content = sContent;
    return gmHaml.execute( gaTemplates[ sDefaultLayout ], oCurrent, aParams );
  } else {
    return sContent;
  }
}

module.exports = Template
