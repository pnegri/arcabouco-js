
class ScrewHTML5SHIV
  bootstrap: ( application ) ->
    return unless application
    application.ContentGenerator.addContentFor 'head', '<!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->'

module.exports = ScrewHTML5SHIV
