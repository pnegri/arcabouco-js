Common = require './common'
Haml = require 'haml'

class Template
  loadedTemplates : []

  ## TODO: Search for Template
  ## TODO: Modulize template for support multiple files

  getTemplate: ( templateFile ) ->
    templateFile = Common.Path.basename templateFile
    unless @loadedTemplates[ templateFile ]
      return false
    @loadedTemplates[ templateFile ]

  loadTemplate: ( templateFile, asTemplateName="" ) ->
    unless templateFile
      return false
    unless templateFile.match /\.haml$/gi
      return false
    baseTemplateFile = Common.Path.basename templateFile
    if asTemplateName != ""
      baseTemplateFile = asTemplateName
    template = Common.Fs.readFileSync templateFile, 'utf-8'
    compiledTemplate = Haml.compile template
    optimizedTemplate = Haml.optimize compiledTemplate
    @loadedTemplates[ baseTemplateFile ] =
      type: 'haml'
      data: optimizedTemplate

  loadTemplateString: ( templateString, templateName ) ->
    @loadedTemplates[ templateName ] =
      type: 'plain'
      data: templateString

  doRender: ( templateFile, context = this, params = {}, layout = 'layout.haml' ) ->
    template = @getTemplate templateFile
    unless template
      return 'Template Missing: ' + templateFile

    if template.type == 'haml'
      content = Haml.execute template.data, context, params
    else
      content = template.data

    if layout
      compiled_layout = @getTemplate layout
      params.content = content
      return Haml.execute layout, context, params
    return content

  doRenderPartial: ( templateFile, context = this, params = {}) ->
    @doRender templateFile, context, params, false

module.exports = Template
