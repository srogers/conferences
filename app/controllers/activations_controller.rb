class ActivationsController < ApplicationController

  before_action :require_no_user

  def create
    @user = User.find_using_perishable_token(params[:id], 1.day)

    if @user
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
      logger.error "Request IP #{ request.ip } attempted to validate with bogus token: #{ params[:id] }"
      flash[:error] = "We're sorry-your account could not be activated. Please contact an administrator."
      redirect_to root_path
    end
  end
end
