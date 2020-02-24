# This is a concern so both publications controller and conferences controller can use it.
module PublicationsChart

  include SharedQueries

  # The controller index action and the chart-building action share these WHERE clauses for consistency. It includes conference
  # and speakers, which makes searches slightly less efficient, but much more in line with what a user would expect re matches.
  def filter_publications(publications)
    query = init_query(publications)
    query = base_query(query)
    query = publication_query(query)

    publications.where(query.where_clause, *query.bindings)
  end

  # Builds a hash of publication counts that looks like: {"Hans Schantz"=>7, "Robert Garmong"=>6, "Ann Ciccolella"=>5, "Yaron Brook"=>5 }
  # which the endpoint can return as JSON or the action can use directly as an array.
  def format_count_data
    # The search term restrictions have the same effect as events/index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if param_context(:search_term).present?
      # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
      # Just have to let the results fly, and hope it's not too huge.
      # This repeats the WHERE clause from the presentations controller so the the chart results will match the search results
      data = Publication.includes(:presentations => :conference).includes(:presentations => :speakers)
      data = filter_publications(data)
      data = data.group("format").order(Arel.sql("count(publications.id) DESC")).count('publications.id')

    # Handles the My Conferences case - TODO does this make sense for Publications?
    elsif param_context(:user_id).present?
      data = Publication.includes(:presentations => :conference).where("conferences.id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).group("format").order("count(publications.id) DESC").count('publications.id')

    else
      # Show the top publications - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off publications with the same count as publications shown, which is misleading.
      # The floor value is a setting, because it changes fairly dynamically as more events are entered.
      # In any case, the floor would never be removed, because the resulting chart would be huge, with mostly bars of height 1 or 2
      data = Publication.group("format").order(Arel.sql("count(publications.id) DESC")).count
    end

    return data
  end

  def publication_year_count_data
    # There is no user-specific publication listing comparable to "My Events" (yet)
    if param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
      # Build a query using the current search term and tag
      query = init_query(Publication)
      query = base_query(query)
      query = publication_aggregate(query)
      results = Publication.group_by_year("publications.published_on").where(query.where_clause, *query.bindings).count

    else
      # Get everything
      results = Publication.group_by_year("publications.published_on").count
    end

    # group_by_year groups by Jan 1 of each year - we want to see only the year
    return results.inject({}) { |h, (k, v)| h.merge( (k.is_a?(Date) ? k.year : k) => v) }
  end

  def publication_duration_year_count_data
    # There is no user-specific publication listing comparable to "My Events" (yet)
    if param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
      # Build a query using the current search term and tag
      query = init_query(Publication) # we can't pre-build the query, but starting with nothing works
      query = base_query(query)
      query = publication_aggregate(query)
      results = Publication.group_by_year("publications.published_on").where(query.where_clause, *query.bindings).sum('duration')

    else
      # Get everything
      results = Publication.group_by_year("publications.published_on").sum('duration')
    end

    # group_by_year groups by Jan 1 of each year - we want to see only the year - duration is in minutes - make it hours
    return results.inject({}) { |h, (k, v)| h.merge( (k.is_a?(Date) ? k.year : k) => v / 60.0 ) }
  end

  def publication_publishers_count_data
    # There is no user-specific "My Publishers" listing comparable to "My Events" (yet) so we don't consider user_id
    if param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
      # Build a query using the current search term and tag
      query = init_query(Publication.includes(:speakers).references(:speakers))
      query = base_query(query)
      query = publication_aggregate(query)
      results = Publication.group("publications.publisher").where(query.where_clause, *query.bindings).count

    else
      # Get everything
      results = Publication.group("publications.publisher").count
    end

    # Since Publisher is a free-form field, it can be null or blank - consolidate those into one key
    results['unspecified'] = results[nil].to_i + results[""].to_i
    results = results.reject{|k,v| k.blank?}

    return results
  end
end
