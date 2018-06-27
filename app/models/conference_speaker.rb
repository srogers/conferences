class ConferenceSpeaker < ApplicationRecord

  belongs_to  :conference
  belongs_to  :speaker

  belongs_to  :creator,   class_name: "User"

end
