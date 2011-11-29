class ScrewMootools
  bootstrap: ( application ) ->
    return unless application

    application.putContentFor 'head',
      '<script src="http://ajax.googleapis.com/ajax/libs/mootools/1.3.2/mootools-yui-compressed.js"></script>',
      'default', { priority: -1000 }

module.exports = ScrewMootools
