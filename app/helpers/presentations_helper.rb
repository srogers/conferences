module PresentationsHelper

  def linked_tag_names(presentation)
    presentation.tag_list.map{|t| link_to t, presentations_path(tag: t)}.join(', ').html_safe
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
end
