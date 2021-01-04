module PresentationsChart

  include SharedQueries         # defines uniform ways for applying search terms - the controller should not include this

  # Sets up the SELECT and FROM in the query - this should be the same everywhere, except possibly some edge cases with aggregates.
  # Pass the results of this into filter_presentations()
  def presentation_collection(collection=Presentation)
    collection.includes(:conference, :publications, :speakers).references(:conference)
  end

  # Set up the query but leave it open so all the filter/aggregate methods can share the same query setup.
  def presentation_query(collection=Presentation)
    query = init_query(presentation_collection(collection))
    if query.tag.present?
      # currently, the caller has to manage includes() and references() and apply them before the where()
      # But we can handle this one, because we know Presentation is the root of the collection.
      query.collection = query.collection.includes(:taggings => :tag).references(:taggings => :tag)
    end
    query = presentation_where(query, SharedQueries::OPTIONAL)
    query = speaker_where(query, SharedQueries::OPTIONAL)
  end

  # The controller index action and the chart-building action share these WHERE clauses for consistency. It includes conference
  # and speakers, which makes searches slightly less efficient, but much more in line with what a user would expect re matches.
  def filter_presentations(collection=Presentation)
    query = presentation_query(collection)
    query.collection.where(query.where_clause, *query.bindings)
  end

  # Builds a hash of presentation counts by year that looks like: {Fri, 01 Jan 1982=>1, Sat, 01 Jan 1983=>2, Sun, 01 Jan 1984=>1, Tue, 01 Jan 1985=>3}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def presentation_count_data
    # Handling search terms for presentations is more complex than speakers or conferences because of tags, so it's handled on the Ruby side
    if param_context(:search_term).present? || param_context(:tag).present?
      collection = Presentation.order(Arel.sql('conferences.start_date DESC, presentations.sortable_name'))
      @presentations = filter_presentations collection
      # Build year keys and counts - use one method or the other
      # keys = @presentations.map{|p| p.conference.start_date.year}.uniq.sort                 # based on just the years that are present
      keys = *(Conference.minimum(:start_date).year..Conference.maximum(:start_date).year)    # a list of all the possible years - reflects full context

      data = keys.inject({}) { |h, v| h.merge(v => @presentations.select{|p| p.conference&.start_date&.year == v}.length) }
      #logger.debug data
    else
      # Show the presentations count by year. This one doesn't need limiting because it naturally has a fixed number of rows.
      data = Presentation.includes(:conference).references(:conference).group_by_year("conferences.start_date").count
    end

    # Return just the year as the hash key - it may be a date or already a just a year
    return data.inject({}) { |h, (k, v)| h.merge( (k.is_a?(Date) ? k.year : k) => v) }
  end

  def speaker_count_data
    # The search term restrictions have the same effect as events/index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if param_context(:search_term).present? || param_context(:tag).present?

      # This is the only place we do a query on PresentationSpeaker, so there isn't a customized builder just for it
      data = PresentationSpeaker.includes(:speaker, :presentation => :conference)
      query = init_query(data)
      if query.tag.present?
        query.collection = query.collection.includes(:presentation => { :taggings => :tag }).references(:presentation => { :taggings => :tag })
      end
      query = speaker_where(query)
      query = presentation_where(query, SharedQueries::OPTIONAL)

      data = query.collection.where(query.where_clause, *query.bindings).group("speakers.name").count(:presentation_id)
      data = data.sort_by{ |k,v| v }.reverse

      # Handles the My Conferences case
    elsif param_context(:user_id).present?
      data = PresentationSpeaker.includes(:speaker, :presentation => :conference).where("conferences.id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).group("speakers.name").order(Arel.sql("count(presentation_id) DESC")).count(:presentation_id)

    else
      # Show the top speakers - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off speakers with the same count as speakers shown, which is misleading.
      # The floor value is a setting, because it changes fairly dynamically as more events are entered.
      # In any case, the floor would never be removed, because the resulting chart would be huge, with mostly bars of height 1 or 2
      data = PresentationSpeaker.includes(:speaker).group("speakers.name").count(:presentation_id)

      # Postgres gets annoyed with HAVING here, and ignores order - results are relatively small, so fix it up in Ruby
      # The floor limit is only applied in this case, where everything is selected, not in the case above with search terms
      data = data.reject{|k,v| v.to_i < Setting.speaker_chart_floor}.sort_by{ |k,v| v }.reverse
    end

    return data
  end

  # Builds a hash of presentation counts by topic that looks like: {'economics'=>1, 'epistemology'=>2}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def topic_count_data
    # If it weren't for the need to support query terms on presentations, we could get the counts directly from the tags table
    # data = ActsAsTaggableOn::Tag.order(Arel.sql('taggings_count DESC').map{|t| [t.name, t.taggings_count]}

    # adding taggings and tags with #load seems to speed things up a little
    # 12/17/19 remove load to perhaps save memory
    collection = Presentation.includes(:publications, :speakers, :taggings, :tags, :conference).references(:taggings, :tags)

    # Handling search terms for presentations is more complex than speakers or conferences because of tags, so it's handled on the Ruby side
    if param_context(:search_term).present? || param_context(:tag).present?
      # This is super-efficient, but it just doesn't get it the right answer
      #query = init_query(@presentations)
      #query = presentation_where(query)
      #data = @presentations.group('tags.name').where(query.where_clause, *query.bindings).count('taggings.taggable_id')

      # Build counts - using the p.tags method instead of p.tag_list requires another map{} but avoids hitting the DB
      @presentations = filter_presentations collection
      keys = *( ActsAsTaggableOn::Tag.order(:name).map{|t| t.name} )   # a list of all the tag names
      data = keys.inject({}) { |h, v| h.merge(v => @presentations.count{|p| p.tags.map{|t| t.name }.include?(v) }) }.reject{|k,v| v == 0 }
    else
      # This works for the simple case with no search term or tags - saves memory
      data = @presentations.group('tags.name').count(:all)
      data = data.reject{|k,v| k.blank?}   # the nil key is probably presentations with no tags - skip that - can't link to them
    end

    return data
  end
end
