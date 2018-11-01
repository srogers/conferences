class PublicationNotificationMailer < ApplicationMailer
  def notify(user, publication)
    @user = user
    @presentation = publication.presentation
    @publication = publication
    mail(to: @user.email, subject: "A presentation you're watching has been published")
  end
end
