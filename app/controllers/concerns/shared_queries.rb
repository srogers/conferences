module SharedQueries

  # It would be cool if the chart and controller searches could call a helper to apply the basic restrictions - but with
  # charts, the group, where, and count must be applied all at once - they aren't intermediate (maybe a fix for that
  # using Arel). Next best thing - the query construction string is defined once.

  class Query
    KINDS = [:required, :optional]
    Atom = Struct.new :kind, :clause, :value

    attr_accessor :atoms, :term, :tag

    def initialize(term, tag)
      @atoms  = []
      @term = term
      @tag = tag
    end

    def add(option, clause, value)
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
      atoms.sort!{ |a,b| b.kind <=> a.kind } # Sort required first, then build clauses and bindings in order

      atoms.each do |atom|
        if atom.kind == :optional
          optionals << atom.clause
        else
          requires << atom.clause
        end
      end

      required_clause = requires.length > 0 ? requires.join(' AND ') : nil
      optional_clause = optionals.length > 0 ? optionals.join(' OR ') : nil
      optional_clause = "(#{ optional_clause })" if optionals.length > 1     # if there's more than one, paren-wrap it

      [required_clause, optional_clause].compact.join(' AND ')
    end

    def bindings
      atoms.sort!{ |a,b| b.kind <=> a.kind } # Sort required first, then build clauses and bindings in order
      atoms.map{|a| a.value}
    end
  end

  # Starts the query construction process by establishing the term and tag
  def init_query
    # Search term comes from explicit queries - tag comes from clicking a tag on a presentation.
    # We combine these to get a broad search - the search term gets initialized with the tag to catch obvious matches lacking an explicit tag.
    # ActiveRecord .or() is weird, so we build an entire query different ways depending on whether term/tag are present.

    term = param_context(:search_term)
    tag  = param_context(:tag)

    if term.blank?
      # set the search term to the tag
      term =  escape_wildcards(param_context(:tag))
      set_param_context :search_term, term
    elsif tag.blank?
      # if the search term exists as a tag and something public is tagged with it, then set it
      if Presentation.tagged_with(term).count > 0
        tag = param_context(:search_term)
        set_param_context :tag, tag
      end
    end
    logger.debug "Term: #{ term }    Tag: #{ tag }"

    Query.new term, tag
  end

  # This defines the query for the main case, shared by all - only name should get leading and trailing wildcard - others
  # just trailing wildcard - year, no wildcard. Year is there to catch special events that don't have the year in the title.
  # Terms:  name, city, country, year, organizer_abbreviation

  def base_query(query)
    if param_context(:event_type).present?
      query.add :required, "conferences.event_type = ?", param_context(:event_type)
      query.add :required, "conferences.event_type = ?", param_context(:event_type)
    end

    if query.term.present?
      query.add :optional, "conferences.name ILIKE ?", "%#{query.term}%"
      query.add :optional, "conferences.city ILIKE ?", "#{query.term}%"
      if country_code(query.term)
        query.add :optional, "conferences.country ILIKE ?", country_code(query.term)
      end
      if query.term.to_i.to_s == query.term && query.term.length == 4 # then this looks like a year
        query.add :optional,"cast(date_part('year',conferences.start_date) as text) = ?", query.term
      end
    end

    return query
  end

  # Extend the base query to do a common query on presentations. The approach depends on the SQL retaining the same
  # order of question marks and bind variables, so when we append query terms and bind variables, everything still lines up.
  def presentation_query(query)
    if query.term.present?
      query.add :optional, 'presentations.name ILIKE ?', "%#{query.term}%"
      query.add :optional, 'speakers.name ILIKE ?', "#{query.term}%"
      query.add :optional, 'speakers.sortable_name ILIKE ?', "#{query.term}%"
    end
    if query.tag.present?
      query.add param_context(:operator) == 'AND' ? :required : :optional, "tags.name = ?", query.tag
    end

    return query
  end

  # This defines the core restriction used to collect counts by user for conferences, cities, years, etc.
  # Since the structure of this query is very different from the base_query, they don't play well together.
  # TODO - might be possible to weld these together dynamically based on presence of :user_id param
  def by_user_query
    "id in (SELECT conference_id FROM conference_users, conferences WHERE conference_users.conference_id = conferences.id AND conference_users.user_id = ? AND conferences.event_type ILIKE ?)"
  end

  private

  # When the tag is used as a wildcard search in the remark space, any wildcard characters needs to be escaped.
  # Wildcards in the search text are allowed, but cause spurious results in tags - e.g. the dot in "this vs. that"
  # NOTE: with JS filtering on tag content, this shouldn't be an issue - but it's still in place just in case.
  def escape_wildcards(text)
    return nil if text.nil?
    text.gsub('.', '\.').gsub('?', '\?').gsub('*', '\*').gsub('-', '\-')
  end

end
