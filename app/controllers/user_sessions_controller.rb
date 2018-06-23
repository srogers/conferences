class UserSessionsController < ApplicationController

  def new
    if current_user
      flash[:error] = "If you want to login as a different user, logout first."
      redirect_to root_path and return
    end
    @user_session = UserSession.new
  end

  def create
    # TODO - seems like there should be a way to do this in UserSession - people often get fooled by pasting a leading space
    params[:user_session].each do |k,v|
      v.strip!
    end

    @user_session = UserSession.new(user_session_params.to_hash)  # TODO - this may get fixed in AuthLogic so the to_h can come off
    if @user_session.save
      flash[:success] = "Welcome back!"
      redirect_to root_path
    else
      render :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:success] = "Goodbye!"
    redirect_to root_path
  end

  private

  def user_session_params
    params.require(:user_session).permit(:email, :password, :remember_me)
  end
end
