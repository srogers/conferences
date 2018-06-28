module ConferencesHelper

  def full_name_with_date(conference)
    "#{conference.organizer.series_name.singularize} #{date_span @conference}"
  end

  def date_span(conference)
    "#{pretty_date conference.start_date, style: :yearless}-#{conference.end_date.day}, #{ conference.end_date.year} "
  end

  # Show a message appropriate for a conference where user is related to conference
  def attendance_status_message(conference)
    if conference.start_date > Date.today
      "You are going!"
    else
      "You were there!"
    end
  end

  # Show a message appropriate for a conference where user is not related
  def attendance_invitation_message(conference)
    if conference.start_date > Date.today
      "I'm going!"
    else
      "I was there!"
    end
  end
end
