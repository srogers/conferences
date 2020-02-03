module PagesHelper

  # This drives only the menu for the semi-static pages, so the keys can just be the action name.
  def tab_active?(current_tab)
    current_tab == action_name ? ' active' : ''
  end
end
