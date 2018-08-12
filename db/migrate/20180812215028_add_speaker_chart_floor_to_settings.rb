class AddSpeakerChartFloorToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column "settings", :speaker_chart_floor, :integer
  end
end
