class ActivationsController < ApplicationController

  def create
    @user = User.find_using_perishable_token(params[:id], 1.day)

    if current_user
      if @user != current_user
        if @user.blank?
          # An already activated and logged in user clicked on their email token again
          logger.warn "User #{ current_user.id }, #{ current_user.email } tried to activate a stale or non-existent token"
          flash[:notice] = "Your account has already been activated"
        else
          # This looks like a logged-in user tried to activate with someone else's token - shenanigans
          logger.warn "User #{ current_user.id }, #{ current_user.email } tried to activate as user ID #{ @user.id }"
          flash[:notice] = "This activation notice is for a different account. Your account is already active."
        end
      end
      redirect_to root_url

    elsif @user
      if @user.active?
        flash[:notice] = "Your account has already been activated"
      else
        @user.activate!
        flash[:notice] = "Your account has been activated!"
      end

      if Setting.require_account_approval? && !@user.approved?
        AccountCreationMailer.pending_activation_notice(@user).deliver_now
        flash[:notice] = "Your email address has been confirmed - account pending administrator approval. You'll receive an email when it's ready."
        redirect_to root_url
      else
        @user.approve!  # approve the account right here - admin never sees it
        UserSession.create(@user, false) # Log user in directly
        # @user.deliver_welcome!
        redirect_to account_url
      end
    else
      # TODO - maybe rate-limit or block this if it gets abused
      logger.warn "Request IP #{ request.ip } attempted to validate with bogus or expired token: #{ params[:id] }"
      flash[:error] = "We're sorry-your account could not be activated. Please contact an administrator."
      redirect_to root_path
    end
  end
end
