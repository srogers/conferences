class EventUsersController < ApplicationController

  include StickyNavigation

  before_action :check_nav_params, only: [:index]
  before_action :require_user

  # authorize_resource - authorization is handled manually via before_filter, and checking show_attendance pref

  def index
    # Users see their own or someone else's conferences in conference/index, where they are searchable as normal.
    # This controller only handles the user side--listing users for a conference.
    redirect_to events_path and return unless params[:conference_id]
    @conference = Conference.find(params[:conference_id])
    @attendees = @conference.users.where("users.show_attendance").page(param_context(:page)).per(param_context(:per))
  end

  def create
    @conference_user = ConferenceUser.new conference_user_params
    @conference_user.user_id = current_user.id unless current_user.admin? # it's all about you unless you're an admin
    @conference_user.creator_id = current_user.id
    if @conference_user.save
      redirect_to event_path(@conference_user.conference_id)
    else
      flash[:error] = "The user/event association could not be saved: #{ @conference_user.errors.full_messages.join(', ') }"
      logger.error "Event Speaker save failed: #{ @conference_user.errors.full_messages.join(', ') }"
      redirect_to events_path
    end
  end

  def destroy
    @conference_user = ConferenceUser.find(params[:id])
    if @conference_user
      conference_id = @conference_user.conference_id
      @conference_user.destroy if @conference_user.user_id == current_user.id || current_user.admin?
      redirect_to event_path(conference_id)
    else
      render body: nil
    end
  end

  def conference_user_params
    params.require(:conference_user).permit(:conference_id, :user_id)
  end
end
