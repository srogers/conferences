class ConferenceUsersController < ApplicationController

  before_action :require_user

  # authorize_resource - authorization is handled manually via before_filter, and checking show_attendance pref

  def index
    if params[:user_id]
      @user = User.find(params[:user_id])
      redirect_to conferences_path and return unless current_user.id.to_s == params[:user_id] || @user.show_attendance || current_user.admin?
      if @user.show_attendance || current_user.id.to_s == params[:user_id]
        @conferences = @user.conferences.order("start_date DESC").page(params[:page]).per(20)
      else
        @conferences = []
      end
      render 'conferences/index'
    elsif params[:conference_id]
      @attendees = Conference.find(params[:conference_id]).users.where("users.show_attendance").page(params[:page]).per(20)
    else
    end
  end

  def create
    @conference_user = ConferenceUser.new conference_user_params
    @conference_user.user_id = current_user.id unless current_user.admin? # it's all about you unless you're an admin
    @conference_user.creator_id = current_user.id
    if @conference_user.save
      redirect_to conference_path(@conference_user.conference_id)
    else
      flash[:error] = 'The user/conference association could not be saved.'
      logger.debug "Conference Speaker save failed: #{ @conference_user.errors.full_messages }"
      redirect_to conferences_path
    end
  end

  def destroy
    @conference_user = ConferenceUser.find(params[:id])
    if @conference_user
      conference_id = @conference_user.conference_id
      @conference_user.destroy if @conference_user.user_id == current_user.id || current_user.admin?
      redirect_to conference_path(conference_id)
    else
      render body: nil
    end
  end

  def conference_user_params
    params.require(:conference_user).permit(:conference_id, :user_id)
  end
end
