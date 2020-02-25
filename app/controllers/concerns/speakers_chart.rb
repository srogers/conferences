# This is a concern so both speakers controller and conferences controller can use it.
module SpeakersChart

  include SharedQueries

  # The controller index action and the chart-building action share these WHERE clauses for consistency. It includes conference
  # and speakers, which makes searches slightly less efficient, but much more in line with what a user would expect re matches.
  def filter_speakers(speakers)
    query = init_query(speakers)
    query = base_query(query)
    query = speaker_query(query)

    speakers.where(query.where_clause, *query.bindings)
  end

  # Builds a hash of speaker counts that looks like: {"Hans Schantz"=>7, "Robert Garmong"=>6, "Ann Ciccolella"=>5, "Yaron Brook"=>5 }
  # which the endpoint can return as JSON or the action can use directly as an array.
  def speaker_presentation_count_data(speaker_slug)
    # The search term restrictions have the same effect as events/index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if param_context(:search_term).present? || param_context(:tag).present?

      # Speaker queries don't reference presentations all - just PresentationSpeakers for counting.
      # Conferences are referenced for the "My Conferences" case
      base = PresentationSpeaker.includes(:speaker, :presentation => :conference)  #.includes(:presentation => { :taggings => :tag }).references(:presentation => { :taggings => :tag })
      query = init_query base
      query = base_query(query)
      query = speaker_query(query)

      data = base.group("speakers.name").where(query.where_clause, *query.bindings).count(:presentation_id)
      data = data.sort_by{ |k,v| v }.reverse

    # Handles the My Conferences case
    elsif param_context(:user_id).present?
      data = PresentationSpeaker.includes(:speaker, :presentation => :conference).where("conferences.id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).group("speakers.name").order(Arel.sql("count(presentation_id) DESC")).count(:presentation_id)

    elsif speaker_slug.present?
      base = PresentationSpeaker.includes(:speaker, :presentation => :conference)
      query = init_query base
      query = base_query(query)
      query = speaker_query(query)
      query = one_speaker_query(query, speaker_slug)

      data = base.group("speakers.name").where(query.where_clause, *query.bindings).count(:presentation_id)

    else
      # Show the top speakers - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off speakers with the same count as speakers shown, which is misleading.
      # The floor value is a setting, because it changes fairly dynamically as more events are entered.
      # In any case, the floor would never be removed, because the resulting chart would be huge, with mostly bars of height 1 or 2
      data = PresentationSpeaker.includes(:speaker).group("speakers.name").count(:presentation_id)

      # Postgres gets annoyed with HAVING here, and ignores order - results are relatively small, so fix it up in Ruby
      # The floor limit is only applied in this case, where everything is selected, not in the case above with search terms
      minimum = Setting.speaker_chart_floor # weirdly, this doesn't get cached if it's in the iterator
      data = data.reject{|k,v| v.to_i < minimum}.sort_by{ |k,v| v }.reverse
    end

    return data
  end

  def event_count_data(speaker_slug)
    # The search term restrictions have the same effect as events/index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if param_context(:search_term).present? || param_context(:tag).present?
      # This repeats the WHERE clause from the conferences controller so the the chart results will match the search results.
      # Start with the Speaker class so SharedQueries will build a speaker-based query
      base = Speaker.includes(:presentations => :conference)
      query = init_query(base)
      query = base_query(query)
      query = speaker_query(query)
      # don't match on presentations in this context - "Smith" matches things like "Adam Smith" in  titles - distracting - do that in the presentations tab
      # query = presentation_query(query)

      data = base.group("speakers.name").where(query.where_clause, *query.bindings).count('conferences.id')
      # do the sort in Ruby - don't filter when a search term is present
      data = data.sort_by{ |name, count| count }.reverse.to_h

    elsif param_context(:user_id).present?
      # Handles the My Conferences case
      data = Conference.includes(:presentations => :speakers).where("conferences.id in (SELECT conferences.id FROM conference_users WHERE user_id = ?)", current_user.id).group("speakers.name").count('conferences.id').sort_by { |name, count| count }.reverse.to_h

    elsif speaker_slug.present?
      base = Speaker.includes(:presentations => :conference)
      query = init_query base
      query = base_query(query)
      query = speaker_query(query)
      query = one_speaker_query(query, speaker_slug)

      data = base.group("speakers.name").where(query.where_clause, *query.bindings).count('conferences.id')
    else
      # Show the top speakers - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off speakers with the same count as speakers shown, which is misleading.
      # The floor value is a setting, because it changes fairly dynamically as more events are entered.
      # In any case, the floor would never be removed, because the resulting chart would be huge, with mostly bars of height 1 or 2
      data = Conference.includes(:presentations => :speakers).group("speakers.name").count('conferences.id')

      # Filter and sort in Ruby, because Postgres hates HAVING in this context
      data = data.reject{|k,v| v.to_i < Setting.speaker_chart_floor}.sort_by{ |name, count| count }.reverse.to_h
    end

    return data.except(nil)  # TODO - for some reason, these have a nil key in the results - is it conferences without any presentations?
  end
end
