module UsersHelper

  # Returns the classes for user tabs based on controller/action/params
  def classes_for_user_tab(name)
    base = ['flex-sm-fill', 'text-sm-center', 'nav-item', 'nav-link'] # classes for bootstrap nav with flex utils
    current = case name
    when 'user_stats'
      if controller_name == 'users' && action_name == 'summary'
        base << 'disabled'
      else
        base << 'active'
      end
    when 'system_stats'
      if controller_name == 'users' && action_name == 'systat'
        base << 'disabled'
      else
        base << 'active'
      end
    when 'watch_list'
      if controller_name == 'user_presentations' && action_name == 'index'
        base << 'disabled'
      else
        base << 'active'
      end
    when 'conferences'
      if controller_name == 'users' && action_name == 'conferences'
        base << 'disabled'
      else
        base << 'active'
      end
    end

    base.join(' ')
  end
end
