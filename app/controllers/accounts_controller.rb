# Handles profile management.
# Routing is setup as a singular resource because we never pass an ID here. Neither Admins
# nor users can change protected attributes by editing their profile. Only Admins can do
# that through the Users controller.
class AccountsController < ApplicationController

  before_action :require_user, :get_current_user

  def show
  end

  def edit
  end

  def update
    if @user.update_attributes user_params
      flash.delete(:error)
      flash[:notice] = 'Your account was successfully updated.'
      redirect_to account_path
    else
      render :action => "edit"
    end
  end

  # Removes all PII and leaves the account in a permanently deactivated state
  def destroy
    logger.info "User ID #{ @user.id } #{ @user.name } self-deleted"
    @user.name = 'Self Deleted'
    @user.email = "self-deleted-#{@user.id}@example.com"
    @user.active = false
    @user.approved = false
    @user.city = ''
    @user.state = ''
    @user.country = ''
    @user.time_zone = ''
    @user.remove_photo = true
    @user.speaker_id = 0
    if @user.save
      logger.info "User #{@user.id} #{ @user.name } self-deleted"
      # redirect_to logout_path  This happens automatically because active and approved were disabled
    else
      logger.error "Error self-deleting user #{@user.id}: #{ @user.errors.full_messages.join(', ')}"
      flash[:notice] = "There was a problem removing your account - please contact an admin."
    end
    redirect_to root_path
  end

  private

  def get_current_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :email, :name, :city, :state, :country, :photo, :remove_photo,
                                 :time_zone, :show_attendance, :show_contributor)
  end
end
