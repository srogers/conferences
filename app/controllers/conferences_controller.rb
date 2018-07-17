class ConferencesController < ApplicationController

  before_action :get_conference, except: [:create, :new, :index]
  before_action :get_organizer_selections, only: [:create, :new, :edit]

  load_and_authorize_resource

  def index
    s = params[:search_term]
    @conferences = Conference.order('start_date DESC').includes(:organizer).references(:organizer)
    @conferences = @conferences.where("Extract(year FROM start_date) = ?", params[:q]) if params[:q].present? && params[:q].length == 4
    @conferences = @conferences.where("organizers.name ILIKE ? OR organizers.series_name ILIKE ? OR organizers.abbreviation ILIKE ?", "%#{s}%", "#{s}%", "#{s}%") if s.present?
    @conferences = @conferences.page(params[:page]).per(20)

    # The JSON result for select2 has to be built with the expected keys
    respond_to do |format|
      format.html
      format.json { render json: { total: @conferences.length, users: @conferences.map{|c| {id: c.id, text: c.name } } } }
    end

  end

  def show
    @conference_user = ConferenceUser.where(conference_id: @conference.id, user_id: current_user&.id).first || ConferenceUser.new
    # These two items are used in building the speaker autocomplete
  end

  def edit
  end

  def new
  end

  def create
    @conference = Conference.new conference_params
    @conference.city&.strip!
    @conference.state&.strip!
    @conference.creator_id = current_user.id
    if @conference.save
      redirect_to conference_path(@conference)
    else
      flash[:error] = 'Your conference could not be saved.'
      logger.debug "Conference save failed: #{ @conference.errors.full_messages }"
      render 'new'
    end
  end

  def update
    if @conference.update_attributes conference_params
      redirect_to conference_path(@conference)
    else
      flash.now[:error] = 'Your conference could not be saved.'
      logger.debug "Conference save failed: #{ @conference.errors.full_messages }"
      render 'edit'
    end
  end

  def destroy
    if can?(:destroy, @conference) && @conference.presentations.empty?
      @conference.destroy
    else
      flash[:notice] = "That conference can't be deleted because it has presentations linked to it."
    end

    redirect_to conferences_path
  end

  private

  def get_conference
    @conference = Conference.find params[:id]
  end

  def get_organizer_selections
    @organizer_selections = Organizer.all.order(:name).map{|o| ["#{o.name} - #{o.series_name}", o.id]}
  end

  def conference_params
    params.require(:conference).permit(:organizer_id, :url, :start_date, :end_date, :venue, :venue_url, :city, :state)
  end
end
