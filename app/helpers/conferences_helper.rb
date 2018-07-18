module ConferencesHelper
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
