module PublicationsHelper

  # Gets an HTML listing of the publications conference names, with canonical ones marked with an icon.
  # The conference name can be plain text, or a link - plain text by default.
  def conference_names(publication, options={})
    linked = options[:linked]
    names = []
    publication.presentation_publications.each do |presentation_publication|
      next unless presentation_publication.presentation.conference_name.present?

      name = ''
      # Start with either a "crown" or indent
      if presentation_publication.canonical
        name += icon('fas', 'crown', :class => 'fa-fw text-warning') + '&nbsp'.html_safe
      else
        name += content_tag(:span, '', class: 'fa fa-fw') + '&nbsp'.html_safe
      end
      # Add the name
      conference = presentation_publication.presentation.conference
      if linked
        # TODO - see whether it's possible to add :sort to sticky_navigation - otherwise it's necessary to reset nav context when switching to conference
        name += link_to truncate(conference.name, length: 80), event_path(conference, nav: 'reset')
      else
        name += truncate(conference.name, length: 80)
      end
      names << name
    end
    ('<br/>' + names.compact.join('<br/>')).html_safe
  end

  def format_and_date(publication)
    if publication.url.present?
      [link_to(icon_for_format(publication)  + ' ' + publication.format, publication.url, target: '_blank'), publication.published_on&.year].compact.join(', ').html_safe
    else
      ["#{ icon_for_format(publication) } #{ publication.format }", publication.published_on&.year].compact.join(', ').html_safe
    end
  end

  # Only the field value itself needs to use this - ordinary show views can use formatted_time()
  def duration_for_display(publication)
    if publication.ui_duration.nil? && !publication.persisted?
      # this is what a create field will get, rather than the normal translation of nil to N/A
      ''
    else
      formatted_time(publication.duration)
    end
  end

  # Converts the duration (integer minutes) into either minutes or hh:mm format, depending on user prefs.
  # For guest users, hh:mm is the default.
  def formatted_time(duration, options={hms: false})
    return 'N/A' if duration.nil? || duration == 0
    seconds = (duration * 60).to_f
    if options[:hms] || defined?(current_user) && current_user&.hms_duration?
      Time.at(seconds).utc.strftime("%H:%M")     # show hh:mm format
    else
      (seconds / 60).round.to_s                  # show raw minutes
    end
  end

  # Converts time in mm or hh:mm format to seconds - simple but not strict format checking
  def unformatted_time(hms)
    return 'n/a' unless hms.include?(':')
    return 'n/a' if hms.count(':') > 2

    # if there is one colon, assume hh:mm - if there are two, assume hh:mm:ss
    factor = hms.count(':') == 2 ? 60.0 : 1.0

    (hms.split(':').reverse.map.with_index{|value, place| value.to_i * 60**place.to_i }.sum / factor).round
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
    when Publication::LP then
      icon('fas', 'compact-disc', 'data-toggle' => "tooltip", title: publication.notes)
    when Publication::CAMPUS then
      icon('fas', 'university')
    when Publication::YOUTUBE then
      icon('fab', 'youtube')
    when Publication::VIMEO then
      icon('fab', 'vimeo')
    when Publication::FACEBOOK then
      icon('fab', 'facebook')
    when Publication::INSTAGRAM then
      icon('fab', 'instagram')
    when Publication::PODCAST then
      icon('fas', 'podcast')
    when Publication::SOUNDCLOUD then
      icon('fab', 'soundcloud')
    when Publication::ONLINE then
      icon('fas', 'download')
    when Publication::ESTORE then
      icon('fas', 'store')
    when Publication::PRINT then
      icon('fas', 'book')
    when Publication::MOKUJI then
      icon('fas', 'tv')
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
