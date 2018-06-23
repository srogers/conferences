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

  private

  def get_current_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :email, :name, :city, :state, :country, :photo, :remove_photo,
                                 :comment_notifications, :time_zone)
  end
end
