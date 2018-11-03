class PublicationNotificationMailer < ApplicationMailer
  def notify(user, presentation_publication)
    @user = user
    @presentation = presentation_publication.presentation
    @publication = presentation_publication.publication
    mail(to: @user.email, subject: "A presentation you're watching has been published")
  end
end
