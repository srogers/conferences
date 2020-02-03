module PassageManagement
  # Controllers use these methods to load up passages into instance variables for views (primarily semi-static pages
  # run under the pages controller.)

  def get_passages
    view = [controller_name, action_name].join('/')
    passages = Passage.where(view: view)
    if passages.empty?
      logger.warn "Found no passages for #{ view }"
    else
      # set each assign variable to the passage, so the view has access to version info, not just content
      passages.each do |passage|
        instance_variable_set('@' + passage.assign_var, passage)
        # prevent the view from saving or updating the passage - only passage UI should do that
        def passage.readonly?; true; end
      end
    end

    # We don't really know whether the view is going to work correctly, just that we found some stuff
    return passages.present?
  end
end
