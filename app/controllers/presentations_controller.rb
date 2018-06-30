class PresentationsController < ApplicationController

  before_action :get_presentation, except: [:create, :new, :index]

  load_and_authorize_resource

  def index
    # This handles the presentation autocomplete
    if params[:q].present?
      @presentations = @presentations.where("lower(presentations.name) like ? OR lower(presentations.name) like ? ", params[:q].downcase + '%', '% ' + params[:q] + '%').limit(params[:per])
    else
      @presentations = Presentation.page(params[:page]).per(20)
    end

    # The json result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json { render json: { total: @presentations.length, users: @presentations.map{|s| {id: s.id, text: s.name } } } }
    end

  end

  def show
    @publication = Publication.new
    @presentation_speaker = PresentationSpeaker.new
    @current_speaker_ids = @presentation.speakers.map{|s| s.id}.join(',')
  end

  def edit
  end

  def new
  end

  def create
    @presentation = Presentation.new presentation_params
    @presentation.name.strip!
    @presentation.creator_id = current_user.id
    if @presentation.save
      if params[:presentation_speaker].present?
        PresentationSpeaker.create(presentation_id: @presentation.id, speaker_id: params[:presentation_speaker][:speaker_id], creator_id: current_user.id)
      end
      redirect_to presentation_path(@presentation)
    else
      flash[:error] = "Your presentation could not be saved: #{ @presentation.errors.full_messages.join(', ') }"
      logger.debug "Presentation save failed: #{ @presentation.errors.full_messages.join(', ') }"
      render 'new'
    end
  end

  def update
    unless @presentation.update_attributes presentation_params
      flash[:error] = 'Your presentation could not be saved.'
      logger.debug "Presentation save failed: #{ @presentation.errors.full_messages }"
    end
    redirect_to presentation_path(@presentation)
  end

  def destroy
    @presentation.destroy

    redirect_to presentations_path
  end

  private

  def get_presentation
    @presentation = Presentation.find params[:id]
  end

  def presentation_params
    params.require(:presentation).permit(:conference_id, :speaker_id, :name, :description, :parts, :duration)
  end
end
