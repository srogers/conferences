module PresentationsHelper

  def format_and_date(publication)
    if publication.url.present?
      link_to(publication.format, publication.url) + ", #{ publication.published_on.year }"
    else
      "#{ publication.format }, #{ publication.published_on.year }"
    end
  end

  def linked_tag_names(presentation)
    presentation.tag_list.map{|t| link_to t, presentations_path(tag: t)}.join(', ').html_safe
  end

  # Get a list of icons corresponding to items in the publication list. The ones that correspond to online media are
  # linked to the relevant URL.
  def linked_format_icons(presentation)
    icon_list = []
    presentation.publications.each do |publication|
      icon = case publication.format
      # Put the tooltip directly on the icons that are unlikely to have links - TODO - enforce which does and doesn't get a link
      when Publication::TAPE then
        icon('fas', 'tape', 'data-toggle' => "tooltip", title: publication.notes)
      when Publication::CD then
        icon('fas', 'compact-disc', 'data-toggle' => "tooltip", title: publication.notes)
      when Publication::VHS then
        icon('fas', 'ticket-alt', 'data-toggle' => "tooltip", title: publication.notes)
      when Publication::DISK then
        icon('fas', 'compact-disc', 'data-toggle' => "tooltip", title: publication.notes)
      when Publication::CAMPUS then
        icon('fas', 'university')
      when Publication::YOUTUBE then
        icon('fab', 'youtube')
      when Publication::PODCAST then
        icon('fas', 'podcast')
      when Publication::ONLINE then
        icon('fas', 'download')
      when Publication::ESTORE then
        icon('fas', 'store')
      else
        icon('fas', 'question-circle')  # This means something was added to Publication FORMATS but not included here
      end

      link_text = publication.url.present? ? link_to(icon, publication.url, 'data-toggle' => "tooltip", title: publication.notes, target: '_blank') : icon # individual publications may or may not be links
      icon_list << link_text
    end

    return icon_list.join(' ').html_safe
  end

  def clickable_speaker_list(presentation)
    speaker_links = []
    presentation.speakers.each do |speaker|
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
