
module ConferencesChart

  # It would be cool if each "count_data" could call a helper to apply the basic restrictions - but the group, where, and count
  # have to be applied all at once - they aren't intermediate (mabye a fix for that using Arel). Next best thing - the
  # query construction string is defined once.

  # This defines the query for the main case, shared by all - only name should get leading and trailing wildcard - others just trailing.
  # Terms:  name, city, country, organizer_abbreviation
  BASE_QUERY = 'conferences.name ILIKE ? OR conferences.city ILIKE ? OR conferences.country = ? OR id in (SELECT c.id FROM conferences c, organizers o WHERE c.organizer_id = o.id AND o.abbreviation ILIKE ?)'

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
        # Just have to let the results fly, and hope it's not too huge.
        results = Conference.group(:city).where(BASE_QUERY, "%#{term}%", "#{term}%", country_code(term), "#{term}%").order("count(city) DESC").count(:city)
      end

      # Handles the My Conferences case
    elsif params[:user_id].present?
      results = Conference.group(:city).where("id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).order("count(city) DESC").count(:city)

    else
      # Show the top cities - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off cities with the same count as cities shown, which is misleading. There is a setting
      # for the speaker chart floor - but not for cities (yet) - 2 works well.
      results = Conference.group(:city).having("count(city) > 1").order("count(city) DESC").count(:city)
    end

    return results
  end

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
        results = Conference.group(:country).where('state ILIKE ?', term).order("count(country) DESC").count
      else
        # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
        # Just have to let the results fly, and hope it's not too huge.
        results = Conference.group(:country).where(BASE_QUERY, "%#{term}%", "#{term}%", country_code(term), "#{term}%").order("count(country) DESC").count
      end

      # Handles the My Conferences case
    elsif params[:user_id].present?
      results = Conference.group(:country).where("id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).order("count(country) DESC").count

    else
      # Show the top countries - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off countries with the same count as countries shown, which is misleading. There is a setting
      # for the speaker chart floor - but not for countries (yet) - 2 works well.
      results = Conference.group(:country).order("count(country) DESC").count
    end

    return results.transform_keys{|k| country_name(k) }
  end


  def year_count_data
    # The search term restrictions have the same effect as index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if params[:search_term].present?
      term = params[:search_term]
      # State-based search doesn't make a lot of sense in this context, but it's here so the results will be consistent
      # when drilling into the data via chart or table. States only match US states - so the country will always be USA.
      if term.length == 2 && States::STATES.map{|term| term[0].downcase}.include?(term.downcase)
        results = Conference.group_by_year("conferences.start_date").where('state ILIKE ?', term).count
      else
        # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
        # Just have to let the results fly, and hope it's not too huge.
        results = Conference.group_by_year("conferences.start_date").where(BASE_QUERY, "%#{term}%", "#{term}%", country_code(term), "#{term}%").count
      end

      # Handles the My Conferences case
    elsif params[:user_id].present?
      results = Conference.group_by_year("conferences.start_date").where("id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).count

    else
      # Show the top countries - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off countries with the same count as countries shown, which is misleading. There is a setting
      # for the speaker chart floor - but not for countries (yet) - 2 works well.
      results = Conference.group_by_year("conferences.start_date").count
    end

    # group_by_year groups by Jan 1 of each year - we want to see only the year
    return results.inject({}) { |h, (k, v)| h.merge( (k.is_a?(Date) ? k.year : k) => v) }
  end
end
