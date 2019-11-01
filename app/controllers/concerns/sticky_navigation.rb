# Used to get certain nav-related params into session, and clear them when switch subject areas
module StickyNavigation

  # Gets the current value of navigation-related params or assigns a default. Stashes current value in session to make
  # it sticky everywhere - with the overall goal of getting consistent nav behavior without littering URLs with params.
  def param_context(param, default='unassigned')
    # logger.debug "params:  #{params.inspect}"
    # logger.debug "session:  #{session.keys}"

    if default=='unassigned'
      default = case param
      when :per         then 10
      when :page        then nil  # omit page entirely instead of making 1 the default
      when :event_type  then nil
      when :search_term then nil
      when :tag         then nil
      when :user_id     then nil
      when :needs_approval then nil
      end
    end
    # return params[param] || default if feature disabled # if there are weird side-effects, might want the ability to turn it off
    if params.has_key?(param)
      session[param] = params[param]
      # as soon as these params are saved, kill them so they won't get sucked into pagination - Kaminari only needs to see page
      params.delete(param) unless param == :page
      session[param]
    else
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
    logger.debug "Deduce Done path from:  session[:via] = #{ session[:via]} params[:nav] = #{ params[:nav]}"
    if session[:via].present?
      # The "Done" path is the path to the original controller/index with sticky params intact.
      # When the current context is a presentation, there are multiple ways we could have gotten there.
      # So try to deduce it from the current instance variables and session[:via]
      if @presentation&.conference && session[:via] == 'events'
        event_path(@presentation.conference)
      elsif @presentation&.speakers&.length == 1 && session[:via] == 'speakers'
        # with multiple speakers, we don't know which one to return to, so just punt that
        speaker_path(@presentation.speakers.first)
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

  private

  def reset_and_remember
    session.delete(:page)
    session.delete(:event_type)
    session.delete(:search_term)
    session.delete(:tag)
    session.delete(:user_id)
    session.delete(:needs_approval)

    session[:via] = controller_name  # remember how we got here

    params[:nav] = nil               # clear this out so it won't get stuck in pagination
  end
end
