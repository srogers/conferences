class ConferenceUsersController < ApplicationController

  before_action :require_user
  before_action :require_admin, except: [:index]

  def index
    if params[:user_id]
      @conferences = User.find(params[:user_id]).conferences.order(:start_date).page(params[:page]).per(20)
      render 'conferences/index'
    elsif params[:conference_id]
      @users = Conference.find(params[:conference_id]).users
    else
    end
  end

  def create
    conference_user = ConferenceUser.new conference_user_params
    conference_user.creator_id = current_user.id
    if conference_user.save
      redirect_to conference_path(conference_user.conference_id)
    else
      flash[:error] = 'The user/conference association could not be saved.'
      logger.debug "Conference Speaker save failed: #{ conference_user.errors.full_messages }"
      redirect_to conferences_path
    end
  end

  def destroy
    conference_user = ConferenceUser.find(params[:id])
    if conference_user
      conference_id = conference_user.conference_id
      conference_user.destroy
      redirect_to conference_path(conference_id)
    else
      render body: nil
    end
  end

  def conference_user_params
    params.require(:conference_user).permit(:conference_id, :user_id)
  end
end
