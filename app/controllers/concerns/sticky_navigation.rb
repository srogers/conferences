# Used to get certain nav-related params into session, and clear them when switch subject areas
module StickyNavigation

  # Gets the current value of navigation-related params or assigns a default. Stashes current value in session to make
  # it sticky everywhere - with the overall goal of getting consistent nav behavior without littering URLs with params.
  def param_context(param, default='unassigned')
    # assign defaults based on the param
    if default=='unassigned'
      default = case param
      when :per   then 10
      when :page  then nil  # omit page entirely instead of making 1 the default
      end
    end
    # return params[param] || default if feature disabled
    if params[param].present?
      session[param] = params[param]
    else
      session[param] || default
    end
  end

end
