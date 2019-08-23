module SharedQueries

  # It would be cool if the chart and controller searches could call a helper to apply the basic restrictions - but with
  # charts, the group, where, and count must be applied all at once - they aren't intermediate (maybe a fix for that
  # using Arel). Next best thing - the query construction string is defined once.

  # This defines the query for the main case, shared by all - only name should get leading and trailing wildcard - others
  # just trailing wildcard - year, no wildcard. Year is there to catch special events that don't have the year in the title.
  # Terms:  name, city, country, year, organizer_abbreviation

  def base_query
    "conferences.event_type LIKE ? AND (conferences.name ILIKE ? OR conferences.city ILIKE ? OR conferences.country = ? OR cast(date_part('year',conferences.start_date) as text) = ? OR conferences.id in (SELECT c.id FROM conferences c, organizers o WHERE c.organizer_id = o.id AND o.abbreviation ILIKE ?))"
  end
end
