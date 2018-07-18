module ConferencesHelper
  # Necessary because of special events
  def fully_qualified_name(conference)
    "#{conference.organizer.abbreviation} #{ date_span conference } #{ conference.location }"
  end

  def date_span(conference)
    start_text = "#{pretty_date conference.start_date, style: :yearless}"
    if conference.start_date == conference.end_date
      end_text = ", #{ conference.end_date.year}"
    else
      end_text = "#{conference.end_date.day}, #{ conference.end_date.year}"
      if conference.start_date.month != conference.end_date.month
        end_text = "#{ I18n.l(Time.now, format: "%B") } " + end_text
      end
      end_text = "-" + end_text
    end
    return start_text + end_text
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
