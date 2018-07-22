class User < ApplicationRecord

  belongs_to :role

  has_many :conference_users,                           :dependent => :destroy
  has_many :conferences, through: :conference_users

  has_many  :created_conferences,            :foreign_key => :creator_id,  :class_name => 'Conference'
  has_many  :created_presentations,          :foreign_key => :creator_id,  :class_name => 'Presentation'
  has_many  :created_speakers,               :foreign_key => :creator_id,  :class_name => 'Speaker'
  has_many  :created_publications,           :foreign_key => :creator_id,  :class_name => 'Publication'
  has_many  :created_presentation_speakers,  :foreign_key => :creator_id,  :class_name => 'PresentationSpeaker'

  validates :name, presence: true
  validates :role, presence: true

  before_validation :clean_email

  mount_uploader :photo, PhotoUploader

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512

    c.validates_uniqueness_of_email_field_options
    c.perishable_token_valid_for 2.days
    c.merge_validates_length_of_password_field_options({:minimum => 7})
  end

  scope :needing_approval, -> { where('not users.approved') }
  scope :editors,          -> { includes('role').references('role').where("roles.name = ?", Role::EDITOR) }

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
    self.active = true
    save
  end

  def approve!
    self.approved = true
    save
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
