module SharedQueries

  # Try to define the SQL query string and bind variables once, and share it across listings and charts, so they are
  # guaranteed to get the same results. Try to do the least amount of restricting and joining necessary to satisfy
  # the query, so performance/memory is optimized.
  #
  # Builds the query string and bind variables for an ActiveRecord call. Callers should get a query object from
  # init_query(), apply where restrictions, then get the results:
  #
  #     query = init_query(ActiveRecord collection)   - builds the query object
  #     query = publication_where(query)              - restricts the query
  #     query = speaker_where(query)
  #     results = query.collection.where(query.where_clause, *query.bindings)
  #
  # The initial collection can be a bare ActiveRecord class, or a class with includes(), references(), and where() pre-applied.
  # The necessary includes() or references() must be supplied with init_query - that doesn't happen automatically.
  # The whole idea is to build queries for views, charts, and exports in a consistent way without repeating code, so
  # the list and the chart for a particular search are always consistent.
  #
  # What the user gets is heaviliy influenced by implicit wildcards and selective use of AND/OR so the results match up
  # with intuitive expectations.

  REQUIRED = :required
  OPTIONAL = :optional
  ADDATIVE = :addative

  class Query
    KINDS = [REQUIRED, OPTIONAL, ADDATIVE]                            # distinguishes things that get AND vs AND (a OR b) vs OR A OR B
    TYPES = [:event, :presentation, :publication, :speaker]           # The query target - customization happens based on this
    Atom = Struct.new :kind, :clause, :value                          # holds all the elements of a term in the WHERE clause

    attr_accessor :collection, :type, :atoms, :terms, :tag

    # Marks a term as handled once it's been added to the where clause, so it doesn't get re-added later.
    # For now, the quick-and-dirty way is to just delete it from the terms list.
    # TODO - if necesssary, make the elements of terms a struct, so each one can literally be marked as handled.
    def handled(term)
      Rails.logger.debug "Deleting #{term} from terms"
      @terms = @terms - [term]
      Rails.logger.debug "Terms:  #{@terms}"
    end

    # Add a clause and corresponding value to the list of clauses that will build the query. For example:
    #   add(REQUIRED, 'table.attribute = ?', 3)
    # It's not necessary to call add() in any particular order. When the query is built, the clauses and bindings will
    # stack out in the right order. Since bindings() does a flatten() on the list, it's possible to "cheat" and pass a
    # string with multiple '?' targets and an array of multiple binding values. It's also possible to add a self-contained
    # clause that requires no bind variable:
    #   add(REQUIRED, 'NOT x.completed')
    # The crucial thing is that clauses and bind variables are stacked in order within each atom, then peeled off in order
    # for the WHERE clause and bindings. The :optional/:required qualifier determines how the atoms get stacked together.
    def add(option, clause, value=nil)
      Rails.logger.debug "Query add #{option} clause #{ clause }  value: #{ value }"
      raise "unknown option for Query atom: #{ option } (must be #{ KINDS.to_sentence(words_connector: ', ', last_word_connector: ' or ')}" unless KINDS.include?(option)
      @atoms << Atom.new(option, clause, value)
    end

    # We're going to build WHERE option with a structure like:
    #    required1 AND required2 AND required3 AND (option1 or option2 or option3) OR addative1 OR addative2
    # Every required item must be present. At least one of the optional items must be present. The addative items have
    # the effect of expanding the result set.
    # The required items cover must-have restrictions like event_type = 'conference', the options are usually about
    # the presence of search text in any of several possible locations, and addative items are rare - things that we
    # want if they match, but which narrow the query too much if they are required. Too many addative items just
    # fetches everything and makes the results muddy and incomprehensible.
    def where_clause
      addatives = []
      optionals = []
      requires  = []
      organize_for_output

      atoms.each do |atom|
        if atom.kind == OPTIONAL
          optionals << atom.clause
        elsif atom.kind == ADDATIVE
          addatives << atom.clause
        else
          requires << atom.clause
        end
      end

      required_clause = requires.length > 0 ? requires.join(' AND ') : nil
      optional_clause = optionals.length > 0 ? optionals.join(' OR ') : nil
      optional_clause = "(#{ optional_clause })" if optionals.length > 1     # if there's more than one, paren-wrap it
      addative_clause = addatives.length > 0 ? addatives.join(' OR ') : nil

      results = [required_clause, optional_clause].compact.join(' AND ')
      results = "#{results} OR #{addative_clause}" if addative_clause

      Rails.logger.debug "WHERE: #{ results }"
      return results
    end

    # Cranks out bind variables for each of the WHERE clause elements, using the same kind of ordering so they match up
    def bindings
      organize_for_output
      results = atoms.map{|a| a.value}.flatten.compact
      Rails.logger.debug "Bindings: #{ results }"
      return results
    end

    def event?
      type == :event
    end

    def presentation?
      type == :presentation
    end

    def publication?
      type == :publication
    end

    def speaker?
      type == :speaker
    end

    private

    # look for a class in the collection - this works because collection always starts with an ActiveRecord class
    def collection_name(collection)
      collection.try(:klass).try(:name) || collection.try(:name)
    end

    # Building the WHERE clause and the bind variables requires the atoms to be sorted. This is non-destructive: more terms
    # can be added to the query and then used again - but sort must be applied each time before the query is used.
    # The where clause and bindings line up because we sort the required items, then optional, then addative, and then
    # build the where clause and bindings in that order.
    def organize_for_output
      atoms.sort!{ |a,b| b.kind <=> a.kind }                         # _r_equired, _o_ptional, _a_ddative
    end

    # Caller begins with query = init_query, which automatically collects term and tag. That can't be built into
    # initialize() because it needs visibility into StickyNavigation.
    def initialize(collection, terms, tag)
      @collection = collection  # an ActiveRecord query collection with a key class at the root - i.e., the result of Presentation.where(...)
      @atoms  = []              # individual elements in the WHERE clause to be joined with AND/OR based on :required vs :optional
      @terms = terms            # an array of the words in the user's search text
      @tag = tag                # currently can only be one tag - TODO support multiple tags with ether/both options
      # TODO - is it possible to set up all the includes() and references() here based on type? Or at least provide a default?
      @type = case collection_name(collection)
      when 'Conference'
        :event
      when 'Presentation'
        :presentation
      when 'Publication'
        :publication
      when 'Speaker'
        :speaker
      when 'PresentationSpeaker'
        :presentation
      else
        # this is a development-level error caused by invalid query setup
        raise "unknown query type #{collection_name(query)}"
      end
    end
  end

  # Callers use this, not Query.new() directly.
  # Starts the query construction process by establishing the search terms and tag (from StickyNavigation).
  # Collection is an ActiveRecord collection begun with one of the key classes, such as:  Presentation.where(..) or Presentation.select(...)
  # The rest of the query is built onto this basic root.
  def init_query(collection, use_term=true, use_tag=true)
    # Search terms come from explicit queries - tag comes from clicking a tag on a presentation.
    # We combine these to get a broad search - the tag gets initialized from the search terms, if it exists.
    # ActiveRecord .or() is weird, so we build an entire query different ways depending on whether term/tag are present.

    # if the caller uses tags, it needs to set the references/includes - we can't do it here, because we don't know the structure of the collection
    use_tag = false unless ['Presentation', 'PresentationSpeaker'].include? collection.try(:klass).try(:name)  # only presentations have tags

    # Build a list of individual search words. These can be overridden so aggregate queries can ignore them.
    terms = use_term && param_context(:search_term).present? ? CSV::parse_line(param_context(:search_term), col_sep: ' ').compact : []
    tag  = use_tag  ? param_context(:tag)&.strip : nil

    if tag.blank? && use_tag
      # if a search term exists as a tag, and something public is tagged with it, then set it.  TODO - is this a good idea? or confusing?
      terms.each do |term|
        if Presentation.tagged_with(term).count > 0
          tag = term
          set_param_context :tag, tag
          break  # so long as we're limited to just one tag, take the first one
        end
      end
    end
    Rails.logger.debug "Initializing Query with #{terms.length} terms: '#{ terms }' and tag: '#{ tag }' (param context tag: '#{param_context(:tag)}')"
    query = Query.new collection, terms, tag
    query = base_query(query)
  end

  # Used to find the city names for multi-venue events, which live at the presentation level.
  def multiples_where(query)
    query.add REQUIRED, "conferences.location_type = ?", Conference::MULTIPLE

    return query
  end

  EVENT_CLAUSES = [
    "conferences.name ILIKE ?",
    "conferences.description ILIKE ?",
    "conferences.city ILIKE ?"
  ].join(' OR ').prepend("(").concat(")")

  # Extend the base query to apply search terms on events.
  def event_where(query)
    query.terms.each do |term|
      if term == Conference::UNSPECIFIED
        query.add REQUIRED, "coalesce(conferences.city, '') = ''"  # this can only get in as a single term
      else
        query.add REQUIRED, EVENT_CLAUSES, ["%#{term}%", "%#{term}%", "#{term}%"]
      end
    end

    return query
  end

  PRESENTATION_CLAUSES = [
    "presentations.name ILIKE ?",
    "presentations.description ILIKE ?",
    "presentations.city ILIKE ?"
  ].join(' OR ').prepend("(").concat(")")

  # Extend the base query to apply search terms and tag to presentations.
  def presentation_where(query, option=REQUIRED)
    if query.terms.present?
      query.terms.each do |term|
        query.add option, PRESENTATION_CLAUSES, ["%#{term}%", "%#{term}%", "#{term}%"]
      end
    end
    # Only Presentations use tags
    if query.tag.present?
      query.add param_context(:operator) == 'AND' ? REQUIRED : OPTIONAL, "tags.name = ?", query.tag
    end

    return query
  end

  PUBLICATION_CLAUSES = [
    "publications.name ILIKE ?",
    "publications.format ILIKE ?",
    "publications.notes ILIKE ?",
    "publications.publisher = ?"
  ].join(' OR ').prepend("(").concat(")")

  # Extends the base query to apply search terms to publications. Publication search uses :optional for these
  # and speaker clauses together, which allows publications to be found by speaker name, but it doesn't shut
  # out things that don't have speakers.
  def publication_where(query, option=REQUIRED)
    if query.terms.present?
      query.terms.each do |term|
        if term == Conference::UNSPECIFIED
          # This is a special term that applies only when clicking out of the publishers chart, where "unspecified" is clickable
          # Get the Physical publications without a publisher
          query.add REQUIRED, "coalesce(publications.publisher, '') = ''"
          query.add REQUIRED, "publications.format in (#{Publication::PHYSICAL.map{|f| "'#{f}'"}.join(', ')})"
        else
          query.add option, PUBLICATION_CLAUSES, ["%#{term}%", "#{term}%", "%#{term}%", term]
        end
      end
    end

    return query
  end

  SPEAKER_CLAUSES = [
    "speakers.name ILIKE ?",
    "speakers.sortable_name ILIKE ?"
  ].join(' OR ').prepend("(").concat(")")

  # Extends the base query to apply search terms to speakers only.
  def speaker_where(query, option=REQUIRED)
    if query.terms.present?
      query.terms.each do |term|
        query.add option, SPEAKER_CLAUSES, ["#{term}%", "#{term}%"]
      end
    end

    return query
  end

  def one_speaker_where(query, speaker_slug)
    # this filters down from the friendly find view of a speaker, so it's the slug, not ActiveRecord ID
    query.add REQUIRED, 'speakers.slug = ?', speaker_slug

    return query
  end

  # This defines the core restriction used to collect counts by user for conferences, cities, years, etc.
  # Get into this by clicking on Events -> My Events -> then pick a chart.
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
      query.add REQUIRED, text, [collect_user_id, param_context(:event_type)]
    else
      text += ")"
      query.add REQUIRED, text, collect_user_id
    end

    return query
  end

  # The chart building methods use this to determine which chart needs to be built
  def collect_user_id
    if param_context(:user_id).present? || param_context(:my_events).present?
      # Handles the My Conferences case - doesn't work with search terms
      param_context(:user_id) || current_user.id
    else
      false
    end
  end

  # Converts a two character code like "US" to full name "United States" - public because a chart uses it to transform keys into
  # user-friendly values.  We use country_code() to transform them back again in queries.
  def country_name(country_code)
    country_object = ISO3166::Country[country_code]
    country_object.translations[I18n.locale.to_s] || country_object.name
  end

  private

  # Get the two character code like "US" from the full name "United States"
  def country_code(country_name)
    country = ISO3166::Country.find_country_by_name(country_name)
    country&.alpha2
  end

  # The idea here is to setup the query based on what's being searched, and initialize the search terms, while leaving
  # the query open for additional refinement via WHERE clauses using any of the xx_where() methods.
  #
  # TODO - can this just be folded into init_query()?  Yes, if by_user_query() can be compatible with it, or erase prior atoms.
  def base_query(query)
    if param_context(:event_type).present? && !query.publication?
      query.add REQUIRED, "conferences.event_type = ?", param_context(:event_type)
    end

    # Scan the query for terms that need to get speical handling
    query.terms.each do |term|
      Rails.logger.debug "base query handling search term #{term}"
      # None of this stuff applies to publications or speakers
      unless query.publication? || query.speaker?
        # Certain special-case terms need to override other optional searches - e.g. if we're looking for country = 'SE,
        # then we can't also say AND (conference.title ILIKE 'SE')
        if country_code(term.upcase)
          Rails.logger.debug "adding required country = #{term}"
          query.add REQUIRED, "conferences.country = ?", country_code(term)
          query.handled(term)
        end
        # State-based search seems like another optional criterion, but it needs to be :required because the state
        # abbreviations are short, they match many incidental things.
        # TODO This doesn't work for international states - might be fixed by going to country_state_select at some point.
        if term.length == 2 && States::STATES.map { |name| name[0] }.include?(term.upcase)
          Rails.logger.debug "adding required state = #{term}"
          query.add REQUIRED, 'conferences.state = ?', term.upcase
          query.handled(term)
        end
      end

      # This applies to presentations and publications, but the query is different
      if term.to_i.to_s == term && term.length == 4 # then this looks like a year
        if query.publication?
          query.add REQUIRED, "cast(date_part('year',publications.published_on) as text) = ?", term
          query.handled(term)
        else
          query.add REQUIRED, "cast(date_part('year',conferences.start_date) as text) = ?", term
          query.handled(term)
        end
      end

      # If the query term is a format, make that a required term
      if query.publication?
        if Publication::FORMATS.map{|f| f.downcase}.include?(term.downcase)
          query.add REQUIRED, "publications.format = ?", term
          query.handled(term)
        end
      end

      # eliminate the relation to organizers.abbreviation, because it's expensive, and not that helpful - it's generally in the title
      #  "conferences.id in (SELECT c.id FROM conferences c, organizers o WHERE c.organizer_id = o.id AND o.abbreviation ILIKE ?)"
    end

    return query
  end

  # When the tag is used as a wildcard search in the remark space, any wildcard characters needs to be escaped.
  # Wildcards in the search text are allowed, but cause spurious results in tags - e.g. the dot in "this vs. that"
  # NOTE: with JS filtering on tag content, this shouldn't be an issue - but it's still in place just in case.
  def escape_wildcards(text)
    return nil if text.nil?
    text.gsub('.', '\.').gsub('?', '\?').gsub('*', '\*').gsub('-', '\-')
  end

end
