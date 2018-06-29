class Publication < ApplicationRecord

  belongs_to  :presentation
  belongs_to  :creator,   class_name: "User"

  validates :presentation_id, presence: true

  TAPE   = 'Tape'
  CD     = 'CD'
  VHS    = 'VHS'
  DISK   = 'DVD/Blu-ray'
  ONLINE = 'Online'
  ESTORE = 'e-Store'
  FORMATS = [TAPE, CD, VHS, DISK, ONLINE, ESTORE]

  validates :format, inclusion: { in: FORMATS, message: "%{value} is not a recognized format" }

end
