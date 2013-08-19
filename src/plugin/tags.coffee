# Public: Tags plugin allows users to tag thier annotations with metadata
# stored in an Array on the annotation as tags.
class Annotator.Plugin.Tags extends Annotator.Plugin
  events:
    'annotationCreated' : 'fetchTags'
    'annotationUpdated' : 'fetchTags'
    'annotationsLoaded' : 'fetchTags'

  options:
    # Configurable function which accepts a string (the contents)
    # of the tags input as an argument, and returns an array of
    # tags.
    parseTags: (string) ->
      string = $.trim(string)

      tags = []
      tags = string.split(/,\s+/) if string
      tags

    # Configurable function which accepts an array of tags and
    # returns a string which will be used to fill the tags input.
    stringifyTags: (array) ->
      array.join(', ')

    # Configurable object that contains the tag API routes
    urls:
      read: '/tags'

    # prefix prepended to all api call urls
    prefix: ''

    availableTags: {}

  previousTags: []

  # The field element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  field: null

  # The input element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  input: null

  # Public: Initialises the plugin and adds custom fields to both the
  # annotator viewer and editor. The plugin also checks if the annotator is
  # supported by the current browser.
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()

    @field = @annotator.editor.addField({
      type:   'select'
      load:   this.updateField
      submit: this.setAnnotationTags
    })

    $(@field).addClass 'tags'

    @annotator.viewer.addField({
      load: this.updateViewer
    })

    # Add a filter to the Filter plugin if loaded.
    if @annotator.plugins.Filter
      @annotator.plugins.Filter.addFilter
        label: Annotator._t('Tag')
        property: 'tag_ids'
        isFiltered: Annotator.Plugin.Tags.filterCallbacks

    @input = $(@field).find(':input')

  # Public: Extracts tags from the provided String.
  #
  # string - A String of tags seperated by spaces.
  #
  # Examples
  #
  #   plugin.parseTags('cake chocolate cabbage')
  #   # => ['cake', 'chocolate', 'cabbage']
  #
  # Returns Array of parsed tags.
  parseTags: (string) ->
    @options.parseTags(string)

  # Public: Takes an array of tags and serialises them into a String.
  #
  # array - An Array of tags.
  #
  # Examples
  #
  #   plugin.stringifyTags(['cake', 'chocolate', 'cabbage'])
  #   # => 'cake chocolate cabbage'
  #
  # Returns Array of parsed tags.
  stringifyTags: (array) ->
    @options.stringifyTags(array)

  # Annotator.Editor callback function. Updates the @input field with the
  # tags attached to the provided annotation.
  #
  # field      - The tags field Element containing the input Element.
  # annotation - An annotation object to be edited.
  #
  # Examples
  #
  #   field = $('<li><input /></li>')[0]
  #   plugin.updateField(field, {tags: ['apples', 'oranges', 'cake']})
  #   field.value # => Returns 'apples oranges cake'
  #
  # Returns nothing.
  updateField: (field, annotation) =>
    value = this.stringifyTags(@previousTags) # default value to the previously selected tags
    value = this.stringifyTags(annotation.tag_ids) if annotation.tag_ids

    if @input.is('select')
      @input.empty()
      thisInput = @input

      for id, tag of @options.availableTags
        option = $('<option />').text(tag).attr 'value', id
        option.attr 'selected', 'selected' if id == value
        thisInput.append option

    else
      @input.val value

    $(".annotator-editor select").trigger 'chosen:updated'

    @input

  # Annotator.Editor callback function. Updates the annotation field with the
  # data retrieved from the @input property.
  #
  # field      - The tags field Element containing the input Element.
  # annotation - An annotation object to be updated.
  #
  # Examples
  #
  #   annotation = {}
  #   field = $('<li><input value="cake chocolate cabbage" /></li>')[0]
  #
  #   plugin.setAnnotationTags(field, annotation)
  #   annotation.tags # => Returns ['cake', 'chocolate', 'cabbage']
  #
  # Returns nothing.
  setAnnotationTags: (field, annotation) =>
    annotation.tag_ids = this.parseTags(@input.val())
    @previousTags = annotation.tag_ids

  # Annotator.Viewer callback function. Updates the annotation display with tags
  # removes the field from the Viewer if there are no tags to display.
  #
  # field      - The Element to populate with tags.
  # annotation - An annotation object to be display.
  #
  # Examples
  #
  #   field = $('<div />')[0]
  #   plugin.updateField(field, {tags: ['apples']})
  #   field.innerHTML # => Returns '<span class="annotator-tag">apples</span>'
  #
  # Returns nothing.
  updateViewer: (field, annotation) =>
    field = $(field)

    _options = @options

    if annotation.tag_ids and $.isArray(annotation.tag_ids) and annotation.tag_ids.length
      field.addClass('annotator-tags').html(->
        string = $.map(annotation.tag_ids,(tag) ->
          if _options.availableTags[tag]
            tagText = _options.availableTags[tag]
          else
            tagText = tag
          '<span class="annotator-tag">' + Annotator.Util.escape(tagText) + '</span>'
        ).join(' ')
      )
    else
      field.remove()

  addNewAvailableTag: (tagName) =>
    @options.availableTags[tagName] = tagName

  fetchTags: () =>
    _options = @options

    setTimeout (->
      url = if _options.prefix? then _options.prefix else ''
      url += _options.urls.read

      $.get url, (data) ->
        if data.ok and data.tags.length
          tags = {}

          # create id/name lookup table
          data.tags.forEach (tag) ->
            tags[tag._id.toString()] = tag.name

          _options.availableTags = tags
    ), 500


# Checks an input string of keywords against an array of tags. If the keywords
# match _all_ tags the function returns true. This should be used as a callback
# in the Filter plugin.
#
# input - A String of keywords from a input field.
#
# Examples
#
#   Tags.filterCallback('cat dog mouse', ['cat', 'dog', 'mouse']) //=> true
#   Tags.filterCallback('cat dog', ['cat', 'dog', 'mouse']) //=> true
#   Tags.filterCallback('cat dog', ['cat']) //=> false
#
# Returns true if the input keywords match all tags.
###
Annotator.Plugin.Tags.filterCallback = (input, tags = []) ->
  matches  = 0
  keywords = []
  if input
    keywords = input.split(/\s+/g)
    for keyword in keywords when tags.length
      matches += 1 for tag in tags when tag.indexOf(keyword) != -1

  matches == keywords.length
###

#
# Function called by chosen to add a new tag
#
window.newAnnotatorTag = (newTag) ->
  $select = $(".annotator-editor select")
  $select.find("option:selected").removeAttr "selected"
  $option = $('<option />').text(newTag).attr 'value', newTag
  $option.attr 'selected', 'selected'
  $select.append $option
  $select.trigger 'chosen:updated'
  $select.closest('.annotator-widget').find('textarea').click()

  ###
  $('.article-paragraphs').each ->
    if $(this).data('annotator')
      $(this).data('annotator').plugins['Tags'].fetchTags()
  ###
