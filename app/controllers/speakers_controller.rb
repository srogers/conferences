class SpeakersController < ApplicationController

  before_action :get_speaker, except: [:create, :new, :index, :presentations_count_by]

  load_and_authorize_resource

  def index
    @speakers = Speaker.order(:sortable_name)
    per_page = params[:per] || 15 # autocomplete specifies :per
    # This handles the speaker autocomplete from the conference show page. Match first characters of first or last name.
    if params[:q].present?
      @speakers = @speakers.where("name ILIKE ? OR name ILIKE ? ", params[:q] + '%', '% ' + params[:q] + '%')
      @speakers = @speakers.where("speakers.id NOT IN (#{params[:exclude].gsub(/[^\d,]/, '')})") if params[:exclude].present?
      @speakers.limit(params[:per]) # :q, :exclude, and :per always go together
    else
      @speakers = @speakers.where("name ILIKE ?", "%#{params[:search_term]}%") if params[:search_term].present?
      @speakers = @speakers.page(params[:page]).per(per_page)
    end

    # The json result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json { render json: { total: @speakers.length, users: @speakers.map{|s| {id: s.id, text: s.name } } } }
    end
  end

  # Feeds the frequent speakers chart
  def presentations_count_by
    results = PresentationSpeaker.includes(:speaker).group("speakers.name").having(["count(presentation_id) >= ?", Setting.speaker_chart_floor]).order("count(presentation_id) DESC").count(:presentation_id)

    respond_to do |format|
      format.html
      format.json { render json: results.to_json }
    end
  end

  def show
    @presentations = @speaker.presentations.includes(:conference).order('conferences.start_date DESC, presentations.sortable_name')
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
      render 'new'
    end
  end

  def update
    if @speaker.update_attributes speaker_params
      redirect_to speaker_path(@speaker)
    else
      flash.now[:error] = 'Your speaker could not be saved.'
      logger.debug "Speaker save failed: #{ @speaker.errors.full_messages }"
      render 'edit'
    end
  end

  def destroy
    if can?(:destroy, @speaker) && @speaker.presentations.empty?
      @speaker.destroy
    else
      flash[:notice] = "Speaker can't be destroyed because it is associated with presentations."
    end

    redirect_to speakers_path
  end

  private

  def get_speaker
    @speaker = Speaker.friendly.find params[:id]
  end

  def speaker_params
    params.require(:speaker).permit(:name, :description, :bio_url, :photo, :remove_photo)
  end
end
