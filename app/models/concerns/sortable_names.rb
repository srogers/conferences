module SortableNames

  # This is shared by Presentation and Publication, but not by Speaker or User, because people names have different considerations.
  def update_sortable_name
    name_parts = name.split(' ')
    if ["a", "an", "the"].include? name_parts[0].downcase
      name_parts.delete_at(0)
      self.sortable_name = name_parts.join(" ")
    else
      self.sortable_name = name
    end
    # If the name starts with a quote, or has a quote after removing fluff words, then throw that character away.
    self.sortable_name[0] = '' if ['"', "'"].include? sortable_name[0] # probably other characters will turn up that should be included
  end

  # Speaker and User call this method
  def update_sortable_human_name
    # If the sortable name has been updated manually, but the name hasn't, then treat that as a manual override.
    # This is necessary with a few unusual names. If the name is updated, sortable name will have to be updated again,
    # but that is unavoidable.
    logger.debug "name_changed?  #{name_changed?}  sortable_name_changed? #{sortable_name_changed?}"
    return if !name_changed? && sortable_name_changed?
    self.sortable_name = name.split(' ').last.capitalize
    logger.debug "sortable name now:  #{sortable_name}"
  end

end
