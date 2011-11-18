class ScrewCompatibleWebApp
  bootstrap: ( application ) ->
    return unless application

    application.ContentGenerator.addContentFor 'start_of_document',
      '<!--[if IEMobile 7]><html class="no-js ie7" manifest="default.appcache?v=1"><![endif]-->'

    application.ContentGenerator.addContentFor 'start_of_document',
      '<!--[if lt IE 7]><html class="no-js ie6"><![endif]-->'

    application.ContentGenerator.addContentFor 'start_of_document',
      '<!--[if IE 7]><html class="no-js ie7"><![endif]-->'

    application.ContentGenerator.addContentFor 'start_of_document',
      '<!--[if IE 8]><html class="no-js ie8"><![endif]-->'

    application.ContentGenerator.addContentFor 'start_of_document',
      '<!--[if (gte IE 9)|(gt IEMobile 7)]><html class="ie9 no-js" manifest="default.appcache?v=1"><![endif]-->'

    application.ContentGenerator.addContentFor 'start_of_document',
      '<!--[if !(IEMobile)|!(IE)><!--><html class="no-js"><!--<![endif]-->'

    application.ContentGenerator.addContentFor 'head',
      '<link rel="canonical" href="/" />'

    application.ContentGenerator.addContentFor 'head',
      '<meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />'

    application.ContentGenerator.addContentFor 'head',
      '<meta http-equiv="cleartype" content="on" />'

    application.ContentGenerator.addContentFor 'head',
      '<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />'

    # TODO: Remove Mootools Dependancy
    application.ContentGenerator.addContentFor 'head',
      '<script type="text/javascript">$$("html").removeClass("no-js").addClass("js");if (Browser.Platform.ios) { $$("html").addClass( "ios" );     }; if (Browser.Platform.android) { $$("html").addClass( "android" ); }; document.addEvent("domready", function() { $$("html").removeClass("not-ready").addClass("ready"); });</script>', { priority: 1000 }

    application.Template.loadTemplate __dirname + '/template/app.no-js.haml', 'compatible.no-js'

    application.ContentGenerator.addContentFor 'start_of_body',
      application.Template.doRenderPartial( 'compatible.no-js' )

    application.ContentGenerator.addContentFor 'end_of_document', '</html>'

module.exports = ScrewCompatibleWebApp
