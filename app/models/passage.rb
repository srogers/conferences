class Passage < ApplicationRecord

  belongs_to  :creator,   class_name: "User"

  attr_accessor :update_type

  MAJOR = 'major'
  MINOR = 'minor'
  UPDATE_TYPES = [MAJOR, MINOR]

  validates :name, :view, :assign_var, :content, :creator_id, presence: true
  validates :update_type,  inclusion: { in: UPDATE_TYPES, message: "%{value} is not a recognized update type", allow_blank: true }     # only present on update

  validates :assign_var, format: { with: /\A[_a-z][_[:alnum:]]*\z/, message: 'must be a legal Ruby variable name', allow_blank: true } # don't double-error message

  before_save :set_versions

  def set_versions
    if persisted?
      if update_type == MAJOR
        self.major_version += 1
        self.minor_version = 0
      else
        self.minor_version += 1
      end

    else # set up versions for a brand new passage
      self.major_version = 1
      self.minor_version = 0
    end
  end

  def version
    if persisted?
      "#{major_version}.#{minor_version}"
    else
      "n/a"
    end
  end
end
