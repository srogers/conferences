module SortableNames

  # This is shared by Presentation and Publication, but not by Speaker, because people names have different considerations.
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

end
