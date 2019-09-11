module PresentationsChart

  # The controller index action and the chart-building action share this filtering code that ensures both tags and searchable
  # items in the presentation are found, but duplicates are eliminated.
  def filter_presentations_by_term(presentations, term)
    # Search term comes from explicit queries - tag comes from clicking a tag on a presentation.
    # Combining these two results ensures that we get both things tagged with the term, as well as things with the term in the name
    presentations.includes(:speakers, :taggings => :tag).references(:taggings => :tag).references(:conferences, :speakers).
      where(base_query + " OR presentations.name ILIKE ? OR speakers.name ILIKE ? OR speakers.sortable_name ILIKE ? OR tags.name = ?",
            # base query bind vars
            event_type_or_wildcard, "%#{term}%", "#{term}%", country_code(term), "#{term}", "#{term}%",
            # bind vars for the 4 literals introduced above
            "%#{term}%", "#{term}%", "#{term}%", term)
  end

  # Builds a hash of presentation counts by year that looks like: {Fri, 01 Jan 1982=>1, Sat, 01 Jan 1983=>2, Sun, 01 Jan 1984=>1, Tue, 01 Jan 1985=>3}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def presentation_count_data

    # Handling search terms for presentations is more complex than speakers or conferences because of tags, so it's handled on the Ruby side
    if params[:search_term].present? || params[:tag].present?
      term = params[:search_term] || params[:tag]

      @presentations = Presentation.includes(:publications, :speakers, :conference => :organizer).order('conferences.start_date DESC, presentations.sortable_name')
      @presentations = filter_presentations_by_term(@presentations, term)

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

  # Builds a hash of presentation counts by topic that looks like: {'economics'=>1, 'epistemology'=>2}
  # which the endpoint can return as JSON or the action can use directly as an array.
  def topic_count_data
    # If it weren't for the need to support query terms on presentations, we could get the counts directly from the tags table
    # data = ActsAsTaggableOn::Tag.order('taggings_count DESC').map{|t| [t.name, t.taggings_count]}

    # adding taggings and tags with #load seems to speed things up a little
    @presentations = Presentation.includes(:publications, :speakers, :taggings, :tags, :conference => :organizer).references(:taggings, :tags).load

    # Handling search terms for presentations is more complex than speakers or conferences because of tags, so it's handled on the Ruby side
    if params[:search_term].present? || params[:tag].present?
      term = params[:search_term] || params[:tag]

      @presentations = @presentations.order('conferences.start_date DESC, presentations.sortable_name')
      @presentations = filter_presentations_by_term(@presentations, term)
    end

    # Build counts - using the p.tags method instead of p.tag_list requires another map{} but avoids hitting the DB
    keys = *( ActsAsTaggableOn::Tag.order(:name).map{|t| t.name} )   # a list of all the tag names
    data = keys.inject({}) { |h, v| h.merge(v => @presentations.count{|p| p.tags.map{|t| t.name }.include?(v) }) }

    return data
  end
end
