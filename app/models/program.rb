class Program < ApplicationRecord

  mount_uploader :attachment, DocumentUploader

  belongs_to :conference
  belongs_to :creator,    class_name: "User"

  validates :name, :description, :conference_id, presence: true
  validates :url, http_url: true, allow_blank: true

  validate :url_or_attachment

  def url_or_attachment
    errors.add(:url, 'Either URL or attachment must be provided') if url.blank? && attachment.blank?
    errors.add(:url, 'Specify either URL or attachment, but not both') if url.present? && attachment.present?
  end

end
