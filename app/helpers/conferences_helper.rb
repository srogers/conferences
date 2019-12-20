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

  def chart_title_with_context(intro_text)
    tag  = param_context(:tag).blank? ? nil : content_tag(:i, param_context(:tag))
    term = param_context(:search_term).blank? ? nil : content_tag(:i, param_context(:search_term))
    (intro_text + ' ' + [tag, term].compact.join(" #{ param_context(:operator)} ")).html_safe
  end

  def activated_event_class(event_type, default_class)
    param_context(:event_type) == event_type ? default_class + ' active' : default_class
  end

  def conference_chart_title(pivot)
    if param_context(:user_id).present? && param_context(:user_id) != current_user.id.to_s
      name = User.find(param_context(:user_id))&.name
      title("#{name}'s #{ current_event_type.pluralize } by #{pivot}")
    elsif param_context(:my_events).present?
      title("Your #{ current_event_type.pluralize } by #{pivot}")
    elsif param_context(:search_term).present?
      title("#{ current_event_type.pluralize } by #{pivot} For #{ [param_context(:search_term), param_context(:tag)].compact.join(' and ') }")
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
