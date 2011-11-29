Common = require __dirname + '/../common'

class ArcaboucoContent
  contentArray        : []

  ensureArray: ( where, group ) ->
    @contentArray[ group ] = [] unless @contentArray[ group ]
    @contentArray[ group ][ where ] = [] unless @contentArray[ group ][ where ]
    true

  putContentFor: ( where, data, options = { group: 'default' } ) ->
    priority = 0
    priority = options.priority if options.priority

    group = 'default'
    group = options.group if options.group

    @ensureArray( where, group )

    type = 'plain'
    type = 'function' if typeof data == 'function'

    @contentArray[ group ][ where ].push
      'type': type
      data: data
      priority: priority

  getContentFor: ( where, options = { group: 'default' } ) ->
    group = options.group

    @ensureArray( where, group )

    content = ''
    priorityArray = Common._.sortBy @contentArray[ group ][ where ],
      ( obj ) ->
        return obj.priority

    for aContent in priorityArray
      output = ''
      if aContent.type == 'plain'
        output = aContent.data
      else
        output = aContent.data()
      content += output
    content

module.exports = ArcaboucoContent
