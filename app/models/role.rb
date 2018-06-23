class Role < ApplicationRecord

  has_many :users

  # These values get defined in the DB by db_seeds. The db:norton task checks for modifications
  ADMIN     = 'admin'
  EDITOR    = 'editor'
  READER    = 'reader'

  # Don't change the order of these, because the ability to reload them via rake db:seed relies on consistent ordering.
  ROLES = [ADMIN, EDITOR, READER]

  validates :name, presence: true, inclusion: ROLES

  # Use these to get a role for assignment:  user.role = Role.admin
  def self.admin
    Role.find_by_name(Role::ADMIN)
  end

  def self.editor
    Role.find_by_name(Role::EDITOR)
  end

  def self.reader
    Role.find_by_name(Role::READER)
  end
end
