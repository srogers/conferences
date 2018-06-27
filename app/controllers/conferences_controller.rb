class ConferencesController < ApplicationController

  before_action :get_conference, except: [:create, :new, :index]
  before_action :get_organizer_selections, only: [:create, :new, :edit]

  load_and_authorize_resource

  def index
    @conferences = Conference.order(:start_date).page(params[:page]).per(20)
  end

  def show
    # These two items are used in building the speaker autocomplete
    @conference_speaker = ConferenceSpeaker.new
    @current_speaker_ids = @conference.speakers.map{|s| s.id}.join(',')
  end

  def edit
  end

  def new
  end

  def create
    @conference = Conference.new conference_params
    @conference.name.strip!
    @conference.city.strip!
    @conference.state.strip!
    @conference.creator_id = current_user.id
    unless @conference.save
      flash[:error] = 'Your conference could not be saved.'
      logger.debug "Conference save failed: #{ @conference.errors.full_messages }"
    end
    redirect_to conference_path(@conference)
  end

  def update
    unless @conference.update_attributes conference_params
      flash[:error] = 'Your conference could not be saved.'
      logger.debug "Conference save failed: #{ @conference.errors.full_messages }"
    end
    redirect_to conference_path(@conference)
  end

  def destroy
    @conference.destroy

    redirect_to conferences_path
  end

  private

  def get_conference
    @conference = Conference.find params[:id]
  end

  def get_organizer_selections
    @organizer_selections = Organizer.all.map{|o| ["#{o.name} - #{o.series_name}", o.id]}
  end

  def conference_params
    params.require(:conference).permit(:organizer_id, :start_date, :end_date, :venue, :venue_url, :city, :state)
  end
end
