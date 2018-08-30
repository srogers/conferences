module SharedQueries

  # It would be cool if the chart and controller searches could call a helper to apply the basic restrictions - but with
  # charts, the group, where, and count must be applied all at once - they aren't intermediate (mabye a fix for that
  # using Arel). Next best thing - the query construction string is defined once.

  # This defines the query for the main case, shared by all - only name should get leading and trailing wildcard - others
  # just trailing wildcard.
  # Terms:  name, city, country, organizer_abbreviation
  BASE_QUERY = 'conferences.name ILIKE ? OR conferences.city ILIKE ? OR conferences.country = ? OR id in (SELECT c.id FROM conferences c, organizers o WHERE c.organizer_id = o.id AND o.abbreviation ILIKE ?)'

end
