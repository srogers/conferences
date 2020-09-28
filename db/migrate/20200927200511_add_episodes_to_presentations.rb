class AddEpisodesToPresentations < ActiveRecord::Migration[5.2]
  def change
    add_column "presentations", :episode, :string
    add_column "conferences", :use_episodes, :boolean
  end
end
