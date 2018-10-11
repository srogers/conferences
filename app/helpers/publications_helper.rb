module PublicationsHelper

  # Gets an HTML listing of the publications conference names, with canonical ones marked with an icon
  def conference_names(publication)
    names = []
    publication.presentation_publications.each do |presentation_publication|
      name = ''
      name += icon('fas', 'crown', :class => 'fa-fw text-warning') + '&nbsp'.html_safe if presentation_publication.canonical
      name += truncate(presentation_publication.presentation.conference_name.to_s, length: 40)
      names << name
    end
    names.join('<br/>').html_safe
  end

  def format_and_date(publication)
    if publication.url.present?
      [link_to(icon_for_format(publication)  + ' ' + publication.format, publication.url, target: '_blank'), publication.published_on&.year].compact.join(', ').html_safe
    else
      ["#{ icon_for_format(publication) } #{ publication.format }", publication.published_on&.year].compact.join(', ').html_safe
    end
  end

  def icon_for_format(publication)
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
    when Publication::FACEBOOK then
      icon('fab', 'facebook')
    when Publication::PODCAST then
      icon('fas', 'podcast')
    when Publication::ONLINE then
      icon('fas', 'download')
    when Publication::ESTORE then
      icon('fas', 'store')
    when Publication::PRINT then
      icon('fas', 'book')
    else
      icon('fas', 'question-circle')  # This means something was added to Publication FORMATS but not included here
    end
  end

  def linked_icon(publication)
    icon = icon_for_format(publication)
    publication.url.present? ? link_to(icon, publication.url, 'data-toggle' => "tooltip", title: publication.notes, target: '_blank') : icon # individual publications may or may not be links
  end

  # Returns true when the presentation/publication relationship is canonical. Used in the form context when we don't
  # have presentation_publication already.
  def canonical?(presentation, publication)
    return false unless presentation.present?
    return false unless publication.present?

    PresentationPublication.where(presentation_id: presentation.id, publication_id: publication.id).first&.canonical
  end
end
