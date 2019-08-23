# This is a concern so both publications controller and conferences controller can use it.
module PublicationsChart

  include SharedQueries

  # Builds a hash of publication counts that looks like: {"Hans Schantz"=>7, "Robert Garmong"=>6, "Ann Ciccolella"=>5, "Yaron Brook"=>5 }
  # which the endpoint can return as JSON or the action can use directly as an array.
  def format_count_data
    # The search term restrictions have the same effect as conferences/index, but are applied differently since this is an aggregate query.
    # Everything has to be applied at once - having, where, and count can't be applied in steps.
    if params[:search_term].present?
      term = params[:search_term]
      # State-based search is singled out, because the state abbreviations are short, they match many incidental things.
      # This doesn't work for international states - might be fixed by going to country_state_select at some point.
      if term.length == 2 && States::STATES.map{|term| term[0].downcase}.include?(term.downcase)
        data = Publication.includes(:presentations => :conference).where("conferences.state = ? AND conferences.event_type LIKE ?", term.upcase, event_type_or_wildcard).group("publications.format").order("count(publications.id) DESC").count('publications.id')

      else
        # We can't set a limit via having here, because the interesting results might be in the 1-2 range.
        # Just have to let the results fly, and hope it's not too huge.
        # This repeats the WHERE clause from the conferences controller so the the chart results will match the search results
        data = Publication.includes(:presentations => {:conference => :organizer }).includes(:presentations => :speakers)
        data = data.where(base_query + ' OR publications.name ILIKE ? OR publications.format ILIKE ? OR speakers.name ILIKE ? OR speakers.sortable_name ILIKE ?', event_type_or_wildcard, "#{term}%", "#{term}%", country_code(term), "#{term}", "#{term}%", "#{term}%", "#{term}%", "#{term}%", "#{term}%").group("format").order("count(publications.id) DESC").count('publications.id')
      end

      # Handles the My Conferences case
    elsif params[:user_id].present?
      data = Publication.includes(:presentations => :conference).where("conferences.id in (SELECT conference_id FROM conference_users WHERE user_id = ?)", current_user.id).group("format").order("count(publications.id) DESC").count('publications.id')

    else
      # Show the top publications - otherwise it's too big - limit is not great here, because even though results are sorted
      # by count, limit might cut off publications with the same count as publications shown, which is misleading.
      # The floor value is a setting, because it changes fairly dynamically as more events are entered.
      # In any case, the floor would never be removed, because the resulting chart would be huge, with mostly bars of height 1 or 2
      data = Publication.group("format").order("count(publications.id) DESC").count
    end

    return data
  end

end
