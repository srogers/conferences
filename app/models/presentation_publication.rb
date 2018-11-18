class PresentationPublication < ApplicationRecord

  belongs_to  :presentation
  belongs_to  :publication

  belongs_to  :creator,   class_name: "User"

  validates :presentation_id, presence: true
  validates :publication_id, presence: true

  after_create  :handle_notifications

  # TODO - hand this off to a sidekiq worker
  def handle_notifications
    logger.debug "handling notifications"
    user_presentations = UserPresentation.where(presentation_id: self.presentation_id, notify_pubs: true)
    user_presentations.each do |user_presentation|
      PublicationNotificationMailer.notify(user_presentation.user, self).deliver_now

      Notification.create user_presentation: user_presentation, presentation_publication: self, sent_at: Time.now.utc
    end
    logger.info "#{ user_presentations.length } publication notices sent"
  end
end
