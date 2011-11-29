class WelcomeController
  index: ( params ) ->
    params.response.respondWith params.app.render( 'welcome.index', this, {}, false )

  bootstrap: ( application ) ->
    return unless application
    application.loadTemplate __dirname + '/views/index.haml', 'welcome.index'

  getRoutes: ->
    '/test' : 'index'

module.exports = WelcomeController
