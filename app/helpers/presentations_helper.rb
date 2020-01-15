module PresentationsHelper

  def linked_tag_names(presentation, options={})
    if options[:class].present?
      tag_options = { class: "linked #{ options[:class] }" }
    else
      tag_options = { class: 'linked' }
    end
    presentation.tags.map{|tag| link_to(text_to_tag(tag, tag_options), presentations_path(tag: tag.name, page: 1)) }.join.html_safe
  end

  # convert the comma-separated tag list into markup that will style them as individual tags.
  def tagify(tag_list, options={})
    if options[:class].present?
      tag_options = { class: options[:class] }
    else
      tag_options = {}
    end
    tag_list.split(',').map{|tag| text_to_tag tag, tag_options}.join.html_safe
  end

  # This shows up only in the annotations control bar, and allows the user to and/or tag and free text search terms.
  def logical_selector
    select_tag("operator", options_for_select([["AND", "AND"],["OR", "OR"]], param_context(:operator)), {:name => "operator"} )
  end

  # Get a list of icons corresponding to items in the publication list. The ones that correspond to online media are
  # linked to the relevant URL.
  def linked_format_icons(presentation)
    icon_list = []
    presentation.publications.each do |publication|
      icon_list << linked_icon(publication)
    end

    return icon_list.join(' ').html_safe
  end

  def clickable_speaker_list(presentation)
    speaker_links = []
    presentation.speakers.order(:sortable_name).each do |speaker|
      speaker_links << link_to(speaker.name, speaker_path(speaker))
    end
    return speaker_links.join(', ').html_safe
  end

  def google_safe(text)
    searchable_title = text.gsub(" ", "+")                        # Google uses pluses for spaces
    searchable_title = searchable_title.delete("^a-zA-Z0-9+\-")   # Add the first speaker as an additional term
    return searchable_title
  end

  # Builds a URL for Google Search that will search on the title and first presenter, to provide an easy way
  # to find copies of the presentation online
  def google_search_url(presentation)
    url = "https://www.google.com/search?&q=%22#{ google_safe(presentation.name) }%22"
    url += "+%22#{ google_safe(presentation.speakers.first.name) }%22" if presentation.speakers.present?
    return url
  end

  # Define hovertip text for buttons that appear in multiple places so they get consistent messaging
  def ht_watch
    'Click to mark as Want to Hear'
  end

  def ht_unwatch
    'Click to revert to Want to Hear'
  end

  def ht_heard
    'Click to mark as Heard'
  end

  def ht_notify
    'Click to receive publication notifications'
  end

  def ht_unnotify
    'Click to stop notifications for this item'
  end

  def ht_details
    'Show details'
  end

  def ht_hide_details
    'Hide details'
  end

  private

  # Handles whatever markup is required to turn plain text into a tag
  #
  def text_to_tag(text, options={})
    if options[:class].present?
      classes = "tags_display #{ options[:class] }"
    else
      classes = 'tags_display'
    end
    content_tag :span, text, class: classes
  end
end
