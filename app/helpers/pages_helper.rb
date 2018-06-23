module PagesHelper

  def menu_attributes(current_tab)
    attrs = { role: "presentation"} # a foo-foo attribute all bootstrap menu items get
    attrs = attrs.merge(class: "active") if current_tab == action_name
    return attrs
  end
end
