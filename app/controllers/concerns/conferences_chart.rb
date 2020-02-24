module ConferencesChart

  include SharedQueries

  # The controller index action and the chart-building action share these WHERE clauses for consistency. It includes conference
  # and speakers, which makes searches slightly less efficient, but much more in line with what a user would expect re matches.
  def filter_events(events)
    query = init_query(events)
    query = base_query(query)
    events_with_presentations_query(query)

    events.where(query.where_clause, *query.bindings)
  end

  # After adjusting the total for multiple and virtual, the rest must be unspecified
  def rename_blank_to_unspecified(results)
    if results[''].present? || results[nil].present?
      results['unspecified'] = results[''].to_i + results[nil].to_i
      results = results.reject{|k,v| k.blank?}
    end
    return results
  end

  def reconcile_multiple(combined, multiple)
    results = {}
    (combined.to_a + multiple.to_a).each do |city, value|
      results.has_key?(city) ? results[city] = results[city] + value : results[city] = value
    end
    results = results.reject{|k,v| k == Conference::MULTIPLE}   # Replace the multiple event count with specific cities

    return results
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

      results = Conference.references(:presentations).group(:city).where(query.where_clause, *query.bindings).order(Arel.sql("count(city) DESC")).count(:city)

    elsif param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
      # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
      # Just have to let the results fly, and hope it's not too huge.
      query = init_query(Conference)
      query = base_query(query)

      # This query will get all the event cities - the multiple, virtual, and unspecified ones will all come out on the empty string key
      combined = Conference.group(:city).where(query.where_clause, *query.bindings).order(Arel.sql("count(city) DESC")).count(:city)

      # Now get the cities out of presentations.city for multi-venue events
      query_m = multiples_query(query)
      multiple = Conference.includes(:presentations).group("presentations.city").where(query_m.where_clause, *query_m.bindings).order(Arel.sql("count(city) DESC")).count(:city)

      logger.debug "combined"
      logger.debug combined.inspect
      logger.debug "multiple"
      logger.debug multiple.inspect

      results = reconcile_multiple(combined, multiple)
      logger.debug "results"
      logger.debug results.inspect

      # In this case, we have to subtract the multiple total from the ambiguous
    else
      # Show the top cities - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off cities with the same count as cities shown, which is misleading. There is a setting
      # for the speaker chart floor - but not for cities (yet) - 2 works well.
      results = Conference.group(:city).having(Arel.sql("count(city) > 1")).order(Arel.sql("count(city) DESC")).count(:city)
    end

    results = rename_blank_to_unspecified(results)
    logger.debug "results"
    logger.debug results.inspect

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
