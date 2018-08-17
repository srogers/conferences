module CitiesChart

  # Builds a hash of speaker counts that looks like: {"Austin"=>7, "Houston"=>6, "Dallas"=>5}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def city_count_data
    # The search term restrictions have the same effect as index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if params[:search_term].present?
      term = params[:search_term]
      # State-based search is singled out, because the state abbreviations are short, they match many incidental things.
      # This doesn't work for international states - might be fixed by going to country_state_select at some point.
      if term.length == 2 && States::STATES.map{|term| term[0].downcase}.include?(term.downcase)
        results = Conference.group(:city).where('state ILIKE ?', term).order("count(city) DESC").count(:city)
      else
        # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
        # Just have to let the results fly, and hope it's not too huge. TODO - maybe set the chart height based on results size
        results = Conference.group(:city).where('city ILIKE ? OR name ILIKE ? OR id in (SELECT c.id FROM conferences c, organizers o WHERE c.organizer_id = o.id AND o.name ILIKE ?)', "%#{term}%", "#{term}%", "%#{term}%").order("count(city) DESC").count(:city)
      end

    # Handles the My Conferences case
    elsif params[:user_id].present?
      results = Conference.group(:city).where("id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).order("count(city) DESC").count(:city)

    else
      # Show the top cities - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off cities with the same count as cities shown, which is misleading. There is a setting
      # for the speaker chart floor - but not for cities (yet) - 2 works well.
      results = Conference.group(:city).having("count(city) > 2").order("count(city) DESC").count(:city)
    end

    return results
  end
end
