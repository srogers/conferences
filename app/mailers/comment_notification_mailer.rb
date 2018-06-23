class CommentNotificationMailer < ApplicationMailer

  def moderator_notice(comment)
    @concept = comment.concept
    @user = @concept.moderator
    # don't get notifications on your own comments
    unless comment.author == @concept.moderator
      mail(to: @user.email, subject: "New comment")
    end
  end

end
