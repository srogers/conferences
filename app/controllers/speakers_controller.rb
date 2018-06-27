class SpeakersController < ApplicationController

  before_action :get_speaker, except: [:create, :new, :index]

  load_and_authorize_resource

  def index
    # This handles the speaker autocomplete from the conference show page. Match first characters of first or last name.
    if params[:q].present?
      @speakers = Speaker.where("lower(speakers.name) like ? OR lower(speakers.name) like ? ", params[:q].downcase + '%', '% ' + params[:q] + '%')
      @speakers = @speakers.where("speakers.id NOT IN (#{params[:exclude].gsub(/[^\d,]/, '')})") if params[:exclude].present?
      @speakers.limit(params[:per]) # :q and :per always go together
    else
      @speakers = Speaker.page(params[:page]).per(20)
    end

    # The json result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json { render json: { total: @speakers.length, users: @speakers.map{|s| {id: s.id, text: s.name } } } }
    end

  end

  def show
  end

  def edit
  end

  def new
  end

  def create
    @speaker = Speaker.new speaker_params
    @speaker.name.strip!
    @speaker.creator_id = current_user.id
    if @speaker.save
      redirect_to speaker_path(@speaker)
    else
      flash[:error] = "Your speaker could not be saved: #{ @speaker.errors.full_messages.join(", ") }"
      logger.debug "Speaker save failed: #{ @speaker.errors.full_messages.join(", ") }"
      redirect_to new_speaker_path
    end
  end

  def update
    unless @speaker.update_attributes speaker_params
      flash[:error] = 'Your speaker could not be saved.'
      logger.debug "Speaker save failed: #{ @speaker.errors.full_messages }"
    end
    redirect_to speaker_path(@speaker)
  end

  def destroy
    @speaker.destroy

    redirect_to speakers_path
  end

  private

  def get_speaker
    @speaker = Speaker.find params[:id]
  end

  def speaker_params
    params.require(:speaker).permit(:name)
  end
end
