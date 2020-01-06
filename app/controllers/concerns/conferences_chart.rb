module ConferencesChart

  include SharedQueries

  # The controller index action and the chart-building action share these WHERE clauses for consistency. It includes conference
  # and speakers, which makes searches slightly less efficient, but much more in line with what a user would expect re matches.
  def filter_events(events)
    query = init_query(events)
    query = base_query(query)

    events.where(query.where_clause, *query.bindings)
  end

  # Builds a hash of speaker counts that looks like: {"Austin"=>7, "Houston"=>6, "Dallas"=>5}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def city_count_data
    # The search term restrictions have the same effect as index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - HAVING, WHERE, and COUNT can't be applied in steps.
    user_id = collect_user_id
    if user_id
      query = init_query(Conference, false, false)    # build an empty query, ignoring tag and term
      query = by_user_query(query)                    # this adds the user-specific constraints - doesn't work with base_query()

      results = Conference.group(:city).where(query.where_clause, *query.bindings).order(Arel.sql("count(city) DESC")).count(:city)

    elsif param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
      # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
      # Just have to let the results fly, and hope it's not too huge.
      query = init_query(Conference) # we can't pre-build the query, but starting with nothing works
      query = base_query(query)

      results = Conference.group(:city).where(query.where_clause, *query.bindings).order(Arel.sql("count(city) DESC")).count(:city)

    else
      # Show the top cities - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off cities with the same count as cities shown, which is misleading. There is a setting
      # for the speaker chart floor - but not for cities (yet) - 2 works well.
      results = Conference.group(:city).having(Arel.sql("count(city) > 1")).order(Arel.sql("count(city) DESC")).count(:city)
    end

    return results
  end

  # Builds a hash of speaker counts that looks like: {"Austin"=>7, "Houston"=>6, "Dallas"=>5}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def country_count_data
    # The search term restrictions have the same effect as index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    user_id = collect_user_id
    if user_id
      # Handles the My Conferences case - doesn't play well with search terms
      query = init_query(Conference, false, false)    # build an empty query, ignoring tag and term
      query = by_user_query(query)                    # this adds the user-specific constraints - doesn't work with base_query()

      results = Conference.group(:country).where(query.where_clause, *query.bindings).order("count(country) DESC").count

    elsif param_context(:search_term).present? || param_context(:event_type).present?
      # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
      # Just have to let the results fly, and hope it's not too huge.
      query = init_query(Conference) # we can't pre-build the query, but starting with nothing works
      query = base_query(query)

      results = Conference.group(:country).where(query.where_clause, *query.bindings).order("count(country) DESC").count

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
    user_id = collect_user_id
    if user_id
      # Handles the My Conferences case - doesn't play well with search term
      query = init_query(Conference, false, false)    # build an empty query, ignoring tag and term
      query = by_user_query(query)                    # this adds the user-specific constraints - doesn't work with base_query()

      results = Conference.group_by_year("conferences.start_date").where(query.where_clause, *query.bindings).count

    elsif param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
      # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
      # Just have to let the results fly, and hope it's not too huge.
      query = init_query(Conference) # we can't pre-build the query, but starting with nothing works
      query = base_query(query)
      results = Conference.group_by_year("conferences.start_date").where(query.where_clause, *query.bindings).count

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
