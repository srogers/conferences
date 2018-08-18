# This is a concern so both speakers controller and conferences controller can use it.
module SpeakersChart

  # Builds a hash of speaker counts that looks like: {"Hans Schantz"=>7, "Robert Garmong"=>6, "Ann Ciccolella"=>5, "Yaron Brook"=>5 }
  # which the endpoint can return as JSON or the action can use directly as an array.
  def speaker_count_data
    # The search term restrictions have the same effect as conferences/index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if params[:search_term].present?
      term = params[:search_term]
      # State-based search is singled out, because the state abbreviations are short, they match many incidental things.
      # This doesn't work for international states - might be fixed by going to country_state_select at some point.
      if term.length == 2 && States::STATES.map{|term| term[0].downcase}.include?(term.downcase)
        data = PresentationSpeaker.includes(:speaker, :presentation => :conference).where("conferences.state ILIKE ?", term).group("speakers.name").order("count(presentation_id) DESC").count(:presentation_id)

      else
        # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
        # Just have to let the results fly, and hope it's not too huge.
        # This repeats the WHERE clause from the conferences controller so the the chart results will match the search results
        data = PresentationSpeaker.includes(:speaker, :presentation => {:conference => :organizer }).group("speakers.name").where("organizers.abbreviation ILIKE ? OR conferences.city ILIKE ? OR conferences.name ILIKE ?", "#{term}%", "#{term}%", "%#{term}%").order("count(presentation_id) DESC").count(:presentation_id)
      end

    # Handles the My Conferences case
    elsif params[:user_id].present?
      data = PresentationSpeaker.includes(:speaker, :presentation => :conference).where("conferences.id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).group("speakers.name").order("count(presentation_id) DESC").count(:presentation_id)

    else
      # Show the top speakers - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off speakers with the same count as speakers shown, which is misleading.
      # The floor value is a setting, because it changes fairly dynamically as more conferences are entered.
      # In any case, the floor would never be removed, because the resulting chart would be huge, with mostly bars of height 1 or 2
      data = PresentationSpeaker.includes(:speaker).group("speakers.name").having(["count(presentation_id) >= ?", Setting.speaker_chart_floor]).order("count(presentation_id) DESC").count(:presentation_id)
    end

    return data
  end

end
