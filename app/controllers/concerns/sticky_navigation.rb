# Used to get certain nav-related params into session, and clear them when switch subject areas
module StickyNavigation

  # Defines the expected param keys and their default values
  DEFAULTS = {
    :page           => nil,
    :per            => 10,
    :chart_type     => nil,
    :event_type     => nil,
    :search_term    => nil,
    :tag            => nil,
    :user_id        => nil,
    :needs_approval => nil,
    :operator       => 'OR',    # may not be necessary
    :my_events      => nil,
  }
  PERSISTENT_DEFAULTS = [:per]  # these don't get cleared

  def set_param_context(key, value)
    session[key] = value
  end

  # Before we save the param into session, ensure the contents are legit - robots tend to inject crap into sort and tag
  def cleaned_copy(param)
    if param == :tag
      params[param].delete('^A-Za-z- ')   # nothing but letters, space, and included dash (tag can have spaces)
    elsif [:page, :per, :user_id].include? param
      params[param].delete('^0-9')        # ensure these are digits
    # elsif param == :sort  per #323 - see if it works to include sort in sticky navigation - and if so, clean it here per #428
    else
      params[param]                       # otherwise, nothing to clean
    end
  end

  # Gets the current value of navigation-related params or assigns a default. Stashes current value in session to make
  # it sticky everywhere - with the overall goal of getting consistent nav behavior without littering URLs with params.
  # In some cases, we want links to clear part of the current context. To do that, pass URL params ?param=blank
  def param_context(param, default='unassigned')
    # logger.debug "params:  #{params.inspect}"
    # logger.debug "session:  #{session.keys}"

    if [:sort].include? param
      raise StandardError, "don't call param_context with #{param} - it can't be stashed."
    end

    if default=='unassigned'
      default = DEFAULTS[param]  # get the default from the pre-defined value
    else
      # allow param_context() to be called directly with 'blank' to kill a current value
      if default == 'blank' && [:user_id].include?(param)
        session.delete(param)
        return nil
      else
        # use the provided value as the default, and save it if nothing is saved
        set_param_context(param, default) if session[param].nil?
      end
    end


    # return params[param] || default if feature disabled # if there are weird side-effects, might want the ability to turn it off
    if params.has_key?(param)
      # send URL params ?param=blank to reset the param context to the default value (usually nil)
      if [:tag, :search_term].include?(param) && params[param] == 'blank'
        if default.nil?
          session.delete(param)
        else
          session[param] = default
        end
      else
        # Tag has a special context that builds until it is reset
        if false # param == :tag # allow multiple tags
          if session[:tag]
            session[:tag] = session[:tag] + ",#{cleaned_copy(param)}"
          else
            session[:tag] = cleaned_copy(param)
          end
        else
          # Save the value from params and return it as the current value
          session[param] = cleaned_copy(param)
        end
      end
      # as soon as these params are saved, kill them so they won't get sucked into pagination - Kaminari only needs to see page
      params.delete(param) unless param == :page
      session[param]
    else
      # return the session value - fall back to default on nil (but not on blank)
      session[param] || default
    end
  end

  # Main index actions do this to clear the sticky nav-related params from session
  def check_nav_params
    # A diamond and :per are forever
    reset_and_remember if params[:nav] == 'reset'
  end

  # At certain critical junctures when navigating "up", the proper direction can be ambiguous without knowing how we got
  # into the current context. E.g., clicking Done on event/show could go up to /events, but if we navigated to the event
  # via a presentation, then it makes sense to go back to that context.
  def deduce_done_path
    logger.debug "Deduce Done path from:  session[:via] = '#{ session[:via]}'   params[:nav] = '#{ params[:nav]}'"
    # a few special cases
    return send("root_path") if action_name == 'summary' && !current_user.admin?
    if session[:via].present?
      # The "Done" path is the path to the original controller/index with sticky params intact.
      # When the current context is a presentation, there are multiple ways we could have gotten there.
      # So try to deduce it from the current instance variables and session[:via]
      if @presentation&.conference && session[:via] == 'events'
        event_path(@presentation.conference)
      elsif @presentation&.speakers&.length == 1 && session[:via] == 'speakers'
        # with multiple speakers, we don't know which one to return to, so just punt that
        speaker_path(@presentation.speakers.first)
      elsif @publication&.presentations&.length == 1 &&  session[:via] == 'presentations'
        # it looks like we got to a publication from a presentation, so go back there if there's a distinct one.
        presentation_path(@publication.presentations.first)
      elsif session[:via] == "pages"
        # This is a special case for searches coming from the landing page. There is no pages_path.
        presentations_path
      else
        send("#{session[:via]}_path")
      end
    else
      # We don't know how we got here, so go to some safe context.
      # This is annoying, but safe, because it will force the user to pick a top-level item and reset the context:
      # root_path
      # This is annoying, but in a different way:
      send("#{controller_name}_path", nav: 'reset')
    end
  end

  # Only index actions should call this. Place as the last line in the action, even after format block.
  # Checks whether the current page context is beyond the last page. This is a stopgap, in case there's a bug in the
  # flow where page isn't reset when it should be. When it is, we redo the index action with a nav reset.
  def repaginate_if_needed(listing)
    return if request.format.json? # doesn't make sense for autocomplete requests
    page = param_context(:page)
    redirect_to send("#{controller_name}_path", nav: 'reset') if page && page.to_i > listing.total_pages && !listing.empty?
  end

  private

  def reset_and_remember
    DEFAULTS.keys.each do |param|
      session.delete(param) unless PERSISTENT_DEFAULTS.include?(param)
    end
    session[:via] = controller_name  # remember how we got here
    params[:nav] = nil               # clear this out so it won't get stuck in pagination
  end
end
