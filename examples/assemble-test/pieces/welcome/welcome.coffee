WelcomeController =
  index: ( params ) ->
    responder = params.response
    template = params.app.Template
    responder.respondWith template.doRender( 'welcome.index', this, {}, false )

  bootstrap: ( application ) ->
    return unless application
    application.Template.loadTemplate __dirname + '/views/index.haml', 'welcome.index'

  getRoutes: ->
    '/test' : 'index'

module.exports = WelcomeController
