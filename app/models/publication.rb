class Publication < ApplicationRecord

  belongs_to  :presentation
  belongs_to  :creator,   class_name: "User"

  validates :presentation_id, presence: true

  # These are just short word strings and not icons because there aren't good icons for making things like DVD and CD distinct.
  TAPE    = 'Tape'
  CD      = 'CD'
  VHS     = 'VHS'
  DISK    = 'DVD/Blu-ray'
  CAMPUS  = 'Campus'
  YOUTUBE = 'YouTube'      # Is it helpful to make this distinct?
  PODCAST = 'Podcast'
  ONLINE  = 'Online'       # Meant to be an "other" catch-all
  ESTORE  = 'e-Store'      # This is going away . . .
  FORMATS = [TAPE, CD, VHS, DISK, CAMPUS, YOUTUBE, PODCAST, ONLINE, ESTORE]

  validates :format, inclusion: { in: FORMATS, message: "%{value} is not a recognized format" }

end
