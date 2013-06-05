# Public: Colors plugin allows users to configure the color of the annotation
class Annotator.Plugin.Colors extends Annotator.Plugin
  # Events and callbacks to bind to the Colors#element.
  events:
    '.annotator-color-option click': '_onColorOptionClick'
    'annotationsLoaded'            : 'setAllHighlights'
    'annotationCreated'            : 'setHighlight'
    'annotationUpdated'            : 'setHighlight'

  options:
    defaultColor: 'rgba(255, 255, 10, 0.3)'
    colorOptions: ['rgba(255, 255, 10, 0.3)', 'rgba(10, 255, 10, 0.3)', 'rgba(255, 10, 10, 0.3)', 'rgba(255, 10, 255, 0.3)', 'rgba(10, 255, 255, 0.3)', 'rgba(10, 10, 255, 0.3)']

  # The field element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  field: null

  # The input element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  input: null

  # Public: Initialises the plugin and adds custom fields to both the
  # annotator viewer and editor. The plugin also checks if the annotator is
  # supported by the current browser.
  pluginInit: ->
    return unless Annotator.supported()

    @field = @annotator.editor.addField({
      label:  Annotator._t('Choose a color') + '\u2026'
      load:   this.updateField
      submit: this.setAnnotationColor
    })

    @annotator.viewer.addField({
      load: this.updateViewer
    })

    @input = $(@field).find(':input')

  # Annotator.Editor callback function. Updates the @input field with the
  # color attached to the provided annotation.
  #
  # field      - The color field Element containing the input Element.
  # annotation - An annotation object to be edited.
  updateField: (field, annotation) =>
    value = (if annotation.color then annotation.color else @options.defaultColor)
    _this = this
    className = undefined

    unless @input.closest('li').find('.annotator-color-options').length
      colors = $.map(@options.colorOptions, (color) ->
        color = Annotator.Util.escape(color)
        active = (if value is color then 'active' else '')
        className = _this.slugify color
        '<span class="annotator-color-option ' + className + ' ' + active + '" style="background-color: ' + color + '" data-color="' + color + '"></span>'
      ).join(' ')

      colors = '<span class="annotator-color-options">' + colors + '</span>'

      @input.after(colors);
    else
      @markActiveSwatch(value)

    @input.val(value).attr "type", "hidden"

  # Annotator.Editor callback function. Updates the annotation field with the
  # data retrieved from the @input property.
  #
  # field      - The color field Element containing the input Element.
  # annotation - An annotation object to be updated.
  setAnnotationColor: (field, annotation) =>
    annotation.color = @input.val()

  # Annotator.Viewer callback function. Updates the annotation display with the color.
  #
  # field      - The Element to populate with the color.
  # annotation - An annotation object to be display.
  updateViewer: (field, annotation) ->
    field = $(field)
    field.addClass('annotator-color')

  setAllHighlights: (annotations) ->
    for annotation in annotations
      @setHighlight annotation
    annotations

  setHighlight: (annotation) ->
    color = annotation.color
    if color
      for highlight in annotation.highlights
        highlight.style.backgroundColor = color
    annotation

  # Changes the color input.
  #
  # event - A click Event object.
  #
  # Returns nothing.
  _onColorOptionClick: (event) ->
    color = $(event.target).data('color')
    @markActiveSwatch(color)
    @input.val color

  markActiveSwatch: (activeColor) ->
    className = @slugify activeColor
    $parent = @input.closest('li').find '.annotator-color-options'
    $parent.find('.annotator-color-option').removeClass 'active'
    $parent.find('.annotator-color-option.' + className).addClass 'active'

  # converts the string into a format that can be used as a css class
  slugify: (string) ->
    string.replace /[\W]*/g, ''
