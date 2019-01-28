class AddSortableNameToPublications < ActiveRecord::Migration[5.2]
  def up
    add_column "publications", :sortable_name, :string
    Publication.find_each do |publication|
      publication.speaker_names = 'unspecified' if publication.speaker_names.blank? # repair this required field
      publication.save # touch each one to generate the new sortable name
    end

    add_index "publications", :sortable_name unless index_exists? "publications", :sortable_name
  end

  def down
    remove_column "publications", :sortable_name
  end
end
