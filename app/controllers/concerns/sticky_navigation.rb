# Used to get certain nav-related params into session, and clear them when switch subject areas
module StickyNavigation

  # Gets the current value of navigation-related params or assigns a default. Stashes current value in session to make
  # it sticky everywhere - with the overall goal of getting consistent nav behavior without littering URLs with params.
  def param_context(param, default='unassigned')
    # assign defaults based on the param
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
    if params[:nav] == 'reset'
      session(:page)
      session(:event_type)
      session(:search_term)
      session(:tag)
      session(:user_id)
      session(:needs_approval)

      # If reset was passed in, delete it so it won't get stuck in the paginator, which repeats all params
      params[:nav] = nil
    end
  end

end
