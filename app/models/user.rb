class User < ApplicationRecord

  belongs_to :role

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
    # Only allow this to happen if the user passed in as the new owner is an admin and the account has been deactivated.
    return false unless owner.admin? && !active?
    # handle each item
    return true
  end
end
