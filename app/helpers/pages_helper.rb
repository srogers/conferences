module PagesHelper

  def tab_active?(current_tab)
    current_tab == action_name ? ' active' : ''
  end
end
