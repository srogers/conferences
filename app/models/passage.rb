class Passage < ApplicationRecord

  belongs_to  :creator,   class_name: "User"

  attr_accessor :update_type

  MAJOR = 'major'
  MINOR = 'minor'
  UPDATE_TYPES = [MINOR, MAJOR] # make minor the first in the drop-down (thus the default)

  # the special entry for the privacy policy - we have to be able to find it
  PRIVACY_POLICY = { name: 'Privacy Policy', assign_var: 'privacy_policy', view: 'pages/privacy_policy' }
  TERMS_OF_SERVICE = { name: 'Terms of Service', assign_var: 'terms_of_service', view: 'pages/terms_of_service' }

  validates :name, :view, :assign_var, :content, :creator_id, presence: true
  validates :update_type,  inclusion: { in: UPDATE_TYPES, message: "%{value} is not a recognized update type", allow_blank: true }     # only present on update

  validates :assign_var, format: { with: /\A[_a-z][_[:alnum:]]*\z/, message: 'must be a legal Ruby variable name', allow_blank: true } # don't double-error message

  validates :name,       uniqueness: true
  validates :assign_var, uniqueness: { scope: :view }

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

  # Don't allow Privacy Policy or Terms of Service to be deleted
  def deletable?
    ![PRIVACY_POLICY[:name], TERMS_OF_SERVICE[:name]].include? name
  end

  # Of all the versioned text entries, the Privacy Policy is a first-class citizen, wired into other models.
  def self.current_privacy_policy_version
    Passage.where(name: PRIVACY_POLICY[:name]).first&.version
  end

  # This gets called at boot time to ensure that the Privacy Policy record exists with the right name.
  def self.ensure_privacy_policy
    return if Rails.env.test?
    begin
      if Passage.where(PRIVACY_POLICY).present?
        logger.debug "Privacy Policy present"
      else
        logger.debug "Creating Privacy Policy base entry"
        passage = create PRIVACY_POLICY.merge(creator: User.find_by_role_id(Role.admin.id), content: "Base Privacy Policy - complete manually")
        logger.error "Error creating base privacy policy: #{ passage.errors.full_messages}" if passage.errors.present?
      end
    rescue Exception => e
      logger.error "Error checking for privacy policy: #{ e }"
    end
  end

  # This gets called at boot time to ensure that the Privacy Policy record exists with the right name.
  def self.ensure_terms_of_service
    return if Rails.env.test?
    begin
      if Passage.where(TERMS_OF_SERVICE).present?
        logger.debug "Terms of Service present"
      else
        logger.debug "Creating Terms of Service base entry"
        passage = create TERMS_OF_SERVICE.merge(creator: User.find_by_role_id(Role.admin.id), content: "Base Terms of Service - complete manually")
        logger.error "Error creating base Terms of Service: #{ passage.errors.full_messages}" if passage.errors.present?
      end
    rescue Exception => e
      logger.error "Error checking for terms of service: #{ e }"
    end
  end
end
