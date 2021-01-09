# This is a concern so both publications controller and conferences controller can use it.
module PublicationsChart

  include SharedQueries

  # Sets up the SELECT and FROM in the query - this should be the same everywhere, except possibly some edge cases with aggregates.
  # Pass the results of this into filter_publications()
  def publication_collection(collection=Publication)
    collection.includes(:presentations => :conference).includes(:presentations => :speakers).references(:presentations => :speakers)
  end

  # Set up the query but leave it open so all the filter/aggregate methods can share the same query setup.
  def publication_query(collection=Publication)
    query = init_query(publication_collection(collection))
    query = publication_where(query, SharedQueries::OPTIONAL)
    query = speaker_where(query, SharedQueries::OPTIONAL) unless query.terms == [Conference::UNSPECIFIED] # this is a chart click on unspecified publishers
    return query
  end

  # Call this with the output of publication_collection(), with any added qualifiers tacked on.
  # The controller index action and the chart-building action share these WHERE clauses for consistency. It includes conference
  # and speakers, which makes searches slightly less efficient, but much more in line with what a user would expect re matches.
  def filter_publications(collection=Publication)
    query = publication_query(collection)
    query.apply_where
  end

  # Builds a hash of publication counts that looks like: {"Hans Schantz"=>7, "Robert Garmong"=>6, "Ann Ciccolella"=>5, "Yaron Brook"=>5 }
  # which the endpoint can return as JSON or the action can use directly as an array.
  def format_count_data
    if param_context(:search_term).present?
      data = filter_publications
      data = data.group("format").order(Arel.sql("count(publications.id) DESC")).count('publications.id')

    # Handles the My Conferences case - TODO does this make sense for Publications?
    elsif param_context(:user_id).present?
      data = Publication.includes(:presentations => :conference).where("conferences.id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).group("format").order(Arel.sql("count(publications.id) DESC")).count('publications.id')

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
    if param_context(:search_term).present?
      query = publication_query
      results = Publication.group_by_year("publications.published_on").from("publications, speakers").where(query.where_clause, *query.bindings).count
    else
      results = Publication.group_by_year("publications.published_on").count
    end

    # group_by_year groups by Jan 1 of each year - we want to see only the year
    return results.inject({}) { |h, (k, v)| h.merge( (k.is_a?(Date) ? k.year : k) => v) }
  end

  def publication_duration_year_count_data
    # There is no user-specific publication listing comparable to "My Events" (yet)
    if param_context(:search_term).present?
      query = publication_query
      results = Publication.group_by_year("publications.published_on").from("publications, speakers").where(query.where_clause, *query.bindings).sum('duration')
    else
      results = Publication.group_by_year("publications.published_on").sum('duration')
    end

    # group_by_year groups by Jan 1 of each year - we want to see only the year - duration is in minutes - make it hours and round it
    return results.inject({}) { |h, (k, v)| h.merge( (k.is_a?(Date) ? k.year : k) => (v / 60.0).round ) }
  end

  def publication_publishers_count_data
    # There is no user-specific "My Publishers" listing comparable to "My Events" (yet) so we don't consider user_id
    if param_context(:search_term).present?
      query = publication_query
      results = Publication.group("publications.publisher").from("publications, speakers").where(query.where_clause, *query.bindings).count
    else
      results = Publication.group("publications.publisher").count
    end

    # Since Publisher is a free-form field, it can be null or blank - consolidate those into one key
    results['unspecified'] = results[nil].to_i + results[""].to_i
    results = results.reject{|k,v| k.blank?}

    return results
  end
end
