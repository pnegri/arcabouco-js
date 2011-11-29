class ScrewCompatibleWebApp
  bootstrap: ( application ) ->
    return unless application

    application.putContentFor 'start_of_document',
      '<!--[if IEMobile 7]><html class="no-js ie7" manifest="default.appcache?v=1"><![endif]-->'

    application.putContentFor 'start_of_document',
      '<!--[if lt IE 7]><html class="no-js ie6"><![endif]-->'

    application.putContentFor 'start_of_document',
      '<!--[if IE 7]><html class="no-js ie7"><![endif]-->'

    application.putContentFor 'start_of_document',
      '<!--[if IE 8]><html class="no-js ie8"><![endif]-->'

    application.putContentFor 'start_of_document',
      '<!--[if (gte IE 9)|(gt IEMobile 7)]><html class="ie9 no-js" manifest="default.appcache?v=1"><![endif]-->'

    application.putContentFor 'start_of_document',
      '<!--[if !(IEMobile)|!(IE)><!--><html class="no-js"><!--<![endif]-->'

    application.putContentFor 'head',
      '<link rel="canonical" href="/" />'

    application.putContentFor 'head',
      '<meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />'

    application.putContentFor 'head',
      '<meta http-equiv="cleartype" content="on" />'

    application.putContentFor 'head',
      '<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />'

    # TODO: Remove Mootools Dependancy
    application.putContentFor 'head',
      '<script type="text/javascript">$$("html").removeClass("no-js").addClass("js");if (Browser.Platform.ios) { $$("html").addClass( "ios" );     }; if (Browser.Platform.android) { $$("html").addClass( "android" ); }; document.addEvent("domready", function() { $$("html").removeClass("not-ready").addClass("ready"); });</script>', { priority: 1000 }

    application.loadTemplate __dirname + '/template/app.no-js.haml', 'compatible.no-js'

    application.putContentFor 'start_of_body',
      application.renderPartial( 'compatible.no-js' )

    application.putContentFor 'end_of_document', '</html>'

module.exports = ScrewCompatibleWebApp
