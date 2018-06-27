module ConferencesHelper

  def full_name_with_date(conference)
    "#{conference.organizer.series_name.singularize} #{date_span @conference}"
  end

  def date_span(conference)
    "#{pretty_date conference.start_date, style: :yearless}-#{conference.end_date.day}, #{ conference.end_date.year} "
  end

end
