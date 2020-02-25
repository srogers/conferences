module SharedQueries

  # Try to define the SQL query string and bind variables once, and share it across listings and charts, so they are
  # guaranteed to get the same results. Try to do the least amount of restricting and joining necessary to satisfy
  # the query, so performance/memory is optimized.

  # Builds the query string and bind variables for an ActiveRecord call.
  # TODO - doesn't handle includes() or references() - the caller has to do that. But seems like it could handle it.
  class Query
    KINDS = [:required, :optional]
    Atom = Struct.new :kind, :clause, :value

    attr_accessor :collection, :atoms, :term, :tag, :skip_optionals

    def skip_optionals!
      @skip_optionals = true
    end

    def skip_optionals?
      @skip_optionals
    end

    # Add a clause and corresponding value to the list of clauses that will build the query. looks like:
    #   :required, 'table.attribute = ?', 3
    # When the query is built, the clauses and bindings will stack out in the right order. Since bindings() does a flatten()
    # on the list, it's possible to cheat and pass a string with multiple '?' targets and an array of multiple binding values.
    # It's also possible to add a self-contained clause that requires no bind variable - the nil acts as a placeholder.
    # The crucial thing is that clauses and bind variables are stacked in order, then peeled off in order for the WHERE clause.
    def add(option, clause, value=nil)
      Rails.logger.debug "Query add #{option} clause #{ clause }  value: #{ value }"
      raise "unknown option for Query atom: #{ option } (must be #{ KINDS.to_sentence(words_connector: ', ', last_word_connector: ' or ')}" unless KINDS.include?(option)
      @atoms << Atom.new(option, clause, value)
    end

    # We're going to build WHERE option with a structure like:
    #    basic1 AND basic2 AND basic3 AND (option1 or option2 or option3)
    # where the basics cover must-have restrictions like event_type = 'conference', and the options are usually about
    # the presence of search text in any of several possible locations.
    def where_clause
      optionals = []
      requires  = []
      organize_for_output

      atoms.each do |atom|
        if atom.kind == :optional && !skip_optionals?
          optionals << atom.clause
        else
          requires << atom.clause
        end
      end

      required_clause = requires.length > 0 ? requires.join(' AND ') : nil
      optional_clause = optionals.length > 0 ? optionals.join(' OR ') : nil
      optional_clause = "(#{ optional_clause })" if optionals.length > 1     # if there's more than one, paren-wrap it

      results = [required_clause, optional_clause].compact.join(' AND ')
      Rails.logger.debug "WHERE: #{ results }"
      return results
    end

    # Cranks out bind variables for each of the WHERE clause elements, using the same kind of ordering so they match up
    def bindings
      organize_for_output
      # Skip optional clauses when one of the special required queries triggers it - but not tags. Flatten because add() can accept array values
      results = atoms.reject{|a| a.kind == :optional && skip_optionals? && !a.clause.include?('tags.name')}.map{|a| a.value}.flatten.compact
      Rails.logger.debug "Bindings: #{ results }"
      return results
    end

    private

    # Building the WHERE clause and the bind variables requires the atoms to be sorted. This is non-destructive-more terms
    # can be added to the query and then used again - but sort must be applied each time before the query is used.
    def organize_for_output
      atoms.sort!{ |a,b| b.kind <=> a.kind }
    end

    # Caller begins with query = init_query, which automatically collects term and tag. That can't be built into
    # initialize() because it needs visibility into StickyNavigation.
    def initialize(collection, term, tag)
      @collection = collection
      @atoms  = []
      @term = term
      @tag = tag
      @skip_optionals = false
    end
  end

  # Starts the query construction process by establishing the term and tag (from StickyNavigation)
  def init_query(collection, use_term=true, use_tag=true)
    # Search term comes from explicit queries - tag comes from clicking a tag on a presentation.
    # We combine these to get a broad search - the search term gets initialized with the tag to catch obvious matches lacking an explicit tag.
    # ActiveRecord .or() is weird, so we build an entire query different ways depending on whether term/tag are present.

    # if the caller uses tags, it needs to set the references/includes - we can't do it here, because we don't know the structure of the collection
    use_tag = false unless ['Presentation', 'PresentationSpeaker'].include? collection.try(:klass).try(:name)  # only presentations have tags

    # These can be overridden so aggregate queries can ignore them
    term = use_term && param_context(:search_term).present? ? param_context(:search_term).split(' ').map{|s| s.strip}.compact.join(' ') : nil
    tag  = use_tag  ? param_context(:tag)&.strip : nil

    if term.blank?
      # set the search term to the tag
      # TODO - per #401 - try not doing this
      # term =  escape_wildcards(param_context(:tag))
      # set_param_context :search_term, term
    elsif tag.blank? && use_tag
      # if the search term exists as a tag and something public is tagged with it, then set it
      if Presentation.tagged_with(term).count > 0
        tag = param_context(:search_term)
        set_param_context :tag, tag
      end
    end
    logger.debug "Initializing Query with term: '#{ term }' and tag: '#{ tag }' (param context tag: '#{param_context(:tag)}')"
    Query.new collection, term, tag
  end

  # This defines the query for the main case, shared by all - only name should get leading and trailing wildcard - others
  # just trailing wildcard - year, no wildcard. Year is there to catch special events that don't have the year in the title.
  # Terms:  name, city, country, year, organizer_abbreviation

  def base_query(query)
    # Deduce what the query is about - the basics depend on that
    publication_query = collection_has?(query, 'Publication')
    event_query = collection_has?(query, 'Conference')
    speaker_query     = collection_has?(query, 'Speaker') || collection_has?(query, 'PresentationSpeaker')

    logger.debug "Publication query: #{publication_query}, Speaker query: #{speaker_query}   (#{query.collection.try(:klass).try(:name)})"
    if param_context(:event_type).present? && !publication_query
      query.add :required, "conferences.event_type = ?", param_context(:event_type)
    end

    if query.term.present?
      # None of this stuff applies to publications or speakers
      unless publication_query || speaker_query
        # Certain special-case terms need to override other optional searches - e.g. if we're looking for country = 'SE,
        # then we can't also say AND (conference.title ILIKE 'SE')
        if country_code(query.term.upcase)
          query.add :required, "conferences.country = ?", country_code(query.term)
          query.skip_optionals!
        end
        # State-based search seems like another optional criterion, but it needs to be :required because the state
        # abbreviations are short, they match many incidental things.
        # TODO This doesn't work for international states - might be fixed by going to country_state_select at some point.
        if  query.term.length == 2 && States::STATES.map { |name| name[0] }.include?(query.term.upcase)
          query.add :required, 'conferences.state = ?', query.term.upcase
          query.skip_optionals!
        end
      end

      # This applies to presentations and publications, but the query is different
      if query.term.to_i.to_s == query.term && query.term.length == 4 # then this looks like a year
        if publication_query
          query.add :required, "cast(date_part('year',publications.published_on) as text) = ?", query.term
        else
          query.add :required, "cast(date_part('year',conferences.start_date) as text) = ?", query.term
        end
        query.skip_optionals!
      end
      # eliminate the relation to organizers.abbreviation, because it's expensive, and not that helpful - it's generally in the title
      #  "conferences.id in (SELECT c.id FROM conferences c, organizers o WHERE c.organizer_id = o.id AND o.abbreviation ILIKE ?)"

      unless query.skip_optionals?
        if publication_query && query.term != 'unspecified' # unspecified is a special term - don't look for name in that case
          query.add :optional, "publications.name ILIKE ?", "%#{query.term}%"
        elsif event_query
          query.add :optional, "conferences.name ILIKE ?", "%#{query.term}%"
          query.add :optional, "conferences.city ILIKE ?", "#{query.term}%"
        end
      end
    end

    return query
  end

  # Used to find the city names for multi-venue events, which live at the presentation level.
  def multiples_query(query)
    query.add :required, "conferences.venue = ?", Conference::MULTIPLE

    return query
  end

  def events_with_presentations_query(query)
    # Add this to events index query so that when series cities show up in charts, clicking them will be able to find
    # the related conference. Don't add it to the base query, because it breaks some simple aggregates.
    if query.term == Conference::UNSPECIFIED
      query.add :optional, "coalesce(conferences.city, '') = ''"
    else
      query.add :optional, "presentations.city ILIKE ?", "#{query.term}%" unless query.skip_optionals?
    end

    return query
  end

  # Extend the base query to do a common query on presentations. The approach depends on the SQL retaining the same
  # order of question marks and bind variables, so when we append query terms and bind variables, everything still lines up.
  def presentation_query(query)
    if query.term.present? && !query.skip_optionals?
      query.add :optional, 'presentations.name ILIKE ?', "%#{query.term}%"
      query.add :optional, 'speakers.name ILIKE ?', "#{query.term}%"
      query.add :optional, 'speakers.sortable_name ILIKE ?', "#{query.term}%"
    end
    # Only Presentations use tags
    if query.tag.present?
      query.add param_context(:operator) == 'AND' ? :required : :optional, "tags.name = ?", query.tag
    end

    return query
  end

  # When group is used, anything affecting SELECT (:include, :references) is ignored, so WHERE can only reference the primary table
  def publication_aggregate(query)
    if query.term.present? && !query.skip_optionals?
      query.add :optional, 'publications.name ILIKE ?', "%#{query.term}%"
      query.add :optional, 'publications.format ILIKE ?', "#{query.term}%"
      query.add :optional, 'publications.publisher = ?', query.term             # only matches when the exact name is kicked over from Publishers
    end

    return query
  end

  def publication_query(query)
    if query.term.present? && !query.skip_optionals?
      if query.term == 'unspecified'
        # This is a special term that applies only when clicking out of the publishers chart, where 'unspecified' is clickable
        # Get the Physical publications without a publisher
        query.add :required, "coalesce(publications.publisher, '') = ''"
        query.add :required, "publications.format in (#{Publication::PHYSICAL.map{|f| "'#{f}'"}.join(', ')})"
      else
        query.add :optional, 'publications.name ILIKE ?', "%#{query.term}%"
        query.add :optional, 'publications.format ILIKE ?', "#{query.term}%"
        query.add :optional, 'publications.publisher = ?', query.term             # only matches when the exact name is kicked over from Publishers
        query.add :optional, 'speakers.name ILIKE ?', "#{query.term}%"
        query.add :optional, 'speakers.sortable_name ILIKE ?', "#{query.term}%"
      end
    end

    return query
  end

  def speaker_query(query)
    if query.term.present? && !query.skip_optionals?
      #query.add :optional, 'presentations.name ILIKE ?', "%#{query.term}%"
      query.add :optional, 'speakers.name ILIKE ?', "#{query.term}%"
      query.add :optional, 'speakers.sortable_name ILIKE ?', "#{query.term}%"
    end

    return query
  end

  def one_speaker_query(query, speaker_slug)
    # this filters down from the friendly find view of a speaker, so it's the slug, not ActiveRecord ID
    query.add :required, 'speakers.slug = ?', speaker_slug

    return query
  end

  # This defines the core restriction used to collect counts by user for conferences, cities, years, etc.
  # Since this query has an aggregate built into it, we can't use the base_query() method
  def by_user_query(query)
    # Build this WHERE clause:
    # WHERE id in (SELECT conference_id FROM conference_users, conferences
    #               WHERE conference_users.conference_id = conferences.id
    #                 AND conference_users.user_id = ?
    #                 AND conferences.event_type ILIKE ?)
    text = "id in (
SELECT conference_id FROM conference_users, conferences
 WHERE conference_users.conference_id = conferences.id
   AND conference_users.user_id = ?"
    if param_context(:event_type).present?
      text += " AND conferences.event_type ILIKE ?)"
      # We have to "cheat" and pass the entire query with bind vars as an array, because bindings() can't build this nested structure
      query.add :required, text, [collect_user_id, param_context(:event_type)]
    else
      text += ")"
      query.add :required, text, collect_user_id
    end

    return query
  end

  # The chart building methods use this to determine which chart needs to be built
  def collect_user_id
    if param_context(:user_id).present? || param_context(:my_events).present?
      # Handles the My Conferences case - doesn't work with search term
      param_context(:user_id) || current_user.id
    else
      false
    end
  end

  private

  # look for a class in the query base - this is how the query is adjusted based on what's being searched
  def collection_has?(query, class_name)
    query.collection.try(:klass).try(:name) == class_name || query.collection.try(:name) == class_name
  end

  # When the tag is used as a wildcard search in the remark space, any wildcard characters needs to be escaped.
  # Wildcards in the search text are allowed, but cause spurious results in tags - e.g. the dot in "this vs. that"
  # NOTE: with JS filtering on tag content, this shouldn't be an issue - but it's still in place just in case.
  def escape_wildcards(text)
    return nil if text.nil?
    text.gsub('.', '\.').gsub('?', '\?').gsub('*', '\*').gsub('-', '\-')
  end

end
