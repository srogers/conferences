class User < ApplicationRecord

  include SortableNames

  #           mailbox             subdomains        TLD
  EMAIL = /\A[A-Z0-9_.&%+\-']+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,25})\z/ix

  belongs_to :role
  belongs_to :speaker

  has_many :conference_users,                           :dependent => :destroy
  has_many :conferences, through: :conference_users

  has_many  :created_conferences,            :foreign_key => :creator_id,  :class_name => 'Conference'
  has_many  :created_presentations,          :foreign_key => :creator_id,  :class_name => 'Presentation'
  has_many  :created_speakers,               :foreign_key => :creator_id,  :class_name => 'Speaker'
  has_many  :created_publications,           :foreign_key => :creator_id,  :class_name => 'Publication'
  has_many  :created_presentation_speakers,  :foreign_key => :creator_id,  :class_name => 'PresentationSpeaker'

  has_many  :user_presentations,                        :dependent => :destroy
  has_many  :presentations, through: :user_presentations    # watches with notify on/off
  has_many  :notifications, through: :user_presentations    # sent notifications

  before_validation :clean_email
  before_save       :update_sortable_human_name   # always do this unless it's been manually changed

  validates :name, presence: true
  validate  :name_not_spam
  validates :role, presence: true


  validates :email, format: { with: EMAIL, message: "should look like an email address." },
            length: { maximum: 100 },
            uniqueness: { case_sensitive: false, if: :will_save_change_to_email? }

  validates :password,
            confirmation: { if: :require_password? },
            length: { minimum: 7, if: :require_password? }

  validates :password_confirmation,
            length: { minimum: 7, if: :require_password? }

  acts_as_authentic do |c|
    c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
    c.crypto_provider = Authlogic::CryptoProviders::SCrypt
    c.perishable_token_valid_for 2.days
  end

  mount_uploader :photo, PhotoUploader

  scope :needing_approval, -> { where('not users.approved') }
  scope :editors,          -> { includes('role').references('role').where("roles.name = ?", Role::EDITOR) }

  def name_not_spam
    spammy = (name =~ /http/) != nil
    spammy = (name.split(" ").length > 3) unless spammy
    errors.add(:name, "should not look like spam.") if spammy
  end

  def hms_duration?
    time_format == Publication::HMS
  end

  def attended?(conference)
    conferences.include? conference
  end

  def clean_email
    email.strip! if email.present?
  end

  def role_name
    role.try(:name) || Role::READER
  end

  def admin?
    role_name == Role::ADMIN
  end

  def editor?
    role_name == Role::EDITOR
  end

  def reader?
    role_name == Role::READER
  end

  def has_photo?
    photo.present?
  end

  def activate!
    # Make sure this doesn't change the persistence_token, even though admin can't normally edit it.
    update_column :active, true
  end

  def approve!
    # Specifically uses the #update_column method which skips callbacks.
    # AuthLogic has an :after_save callback that updates perishable_token every time the user is saved - not just when
    # the validation time expires. The perishable token has to stay the same from the time the validation email is sent
    # until the user clicks on it. In cases where the admin approves the account before then the user clicks the
    # validation link, the perishable token has to remain consistent or the user's validation URL will be invalid.
    # This is a dumb design, because any other edit by admin during this period will invalidate the user's URL.
    # We try to prevent that by making the user account uneditable while it is waiting for approval - but the admin
    # does need the ability to approve during this window.
    update_column :approved, true
  end

  # Uses translations provided by country_select gem to convert the country_code to country name
  def country_name
    if country.present?
      country_object = ISO3166::Country[country]
      country_object.translations[I18n.locale.to_s] || country_object.name
    else
      "n/a"
    end
  end

  # Shows the user's location without country, with a short country abbreviation, or full country name depending on options.
  # Part of ApplicationHelper location() and location_with_non_us_country() which works symmetrically for users and conferences.
  def location(options={})
    elements = [city.presence, state.presence]
    elements << [country_name.presence] if options[:country_format] == :full
    elements << [country.presence] if options[:country_format]  == :short
    elements.compact.join(', ')
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    PasswordResetMailer.reset_email(self).deliver_now
  end

  def deliver_verify_email!(creator)
    reset_perishable_token!
    AccountCreationMailer.verify_email(self,creator).deliver_now
  end

  def deliver_activation_notice!
    AccountCreationMailer.activation_notice(self).deliver_now
  end

  def privacy_policy_current?
    major, minor = Passage.current_privacy_policy_version&.split('.')
    user_major, user_minor = privacy_policy_version.split('.')
    major == user_major && minor == user_minor
  end

  # The pages controller calls this to mark the user as having seen the current Privacy Policy when it is served
  def privacy_policy_current!
    version = Passage.current_privacy_policy_version
    update_column(:privacy_policy_version, version) unless privacy_policy_version == version
  end

  # shift all the user's content items to a new owner in preparation for deletion
  def pwnd!(owner)
    # Only allow this to happen if the user passed in as the new owner is an admin and the user account has been deactivated.
    return false unless owner.admin? && !approved?
    # handle each item

    created_conferences.each do |conference|
      conference.update_attribute :creator_id, owner.id
    end

    created_presentations.each do |presentation|
      presentation.update_attribute :creator_id, owner.id
    end

    created_speakers.each do |speaker|
      speaker.update_attribute :creator_id, owner.id
    end

    created_publications.each do |publication|
      publication.update_attribute :creator_id, owner.id
    end

    created_presentation_speakers.each do |presentation_speaker|
      presentation_speaker.update_attribute :creator_id, owner.id
    end

    return true
  end
end
