module ConferencesHelper
  # Show a message appropriate for the user's relationship to the conference.
  # Adding presents a button with the new state "I was there"
  # Removing presents a confirmation "You were there" with the trash icon to remove.
  def attendance_status_message(conference)
    if conference.future?
      if current_user.attended? conference
        # This is what the user sees as attendance confirmation, with the trash icon beside it.
        "You are going!"
      else
        # This is what the user sees on the button to confirm attendance
        "I am going!"
      end
    else
      if current_user.attended? conference
        "You were there!"
      else
        "I was there!"
      end
    end
  end

  def conference_chart_title(pivot)
    if params[:user_id].present?
       title("Your #{ current_event_type.pluralize } by #{pivot}")
    elsif params[:search_term].present?
      title("#{ current_event_type.pluralize } by #{pivot} For #{ params[:search_term]}")
    else
      title("#{ current_event_type.pluralize} by #{pivot}")
    end
  end

  # Returns a value that can be passed into ChartKick for height that will generate a reasonable size for all bars
  def bar_chart_height(bar_count)
    "#{bar_count * 25 + 50}px"
  end

  def name_blank_or_default?(conference)
    conference.name.blank? || conference.name == conference.organizer.abbreviation + ' ' + conference.start_date.year.to_s
  end
end
