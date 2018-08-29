module CountriesChart

  # Builds a hash of speaker counts that looks like: {"Austin"=>7, "Houston"=>6, "Dallas"=>5}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def country_count_data
    # The search term restrictions have the same effect as index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if params[:search_term].present?
      term = params[:search_term]
      # State-based search doesn't make a lot of sense in this context, but it's here so the results will be consistent
      # when drilling into the data via chart or table. States only match US states - so the country will always be USA.
      if term.length == 2 && States::STATES.map{|term| term[0].downcase}.include?(term.downcase)
        results = Conference.group(:country).where('state ILIKE ?', term).order("count(country) DESC").count(:country)
      else
        # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
        # Just have to let the results fly, and hope it's not too huge.
        results = Conference.group(:country).where('country ILIKE ? OR name ILIKE ? OR id in (SELECT c.id FROM conferences c, organizers o WHERE c.organizer_id = o.id AND o.name ILIKE ?)', "%#{term}%", "#{term}%", "%#{term}%").order("count(country) DESC").count(:country)
      end

      # Handles the My Conferences case
    elsif params[:user_id].present?
      results = Conference.group(:country).where("id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).order("count(country) DESC").count(:country)

    else
      # Show the top countries - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off countries with the same count as countries shown, which is misleading. There is a setting
      # for the speaker chart floor - but not for countries (yet) - 2 works well.
      results = Conference.group(:country).order("count(country) DESC").count(:country)
    end

    return results.transform_keys{|k| country_name(k) }
  end
end
