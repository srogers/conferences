class PresentationsController < ApplicationController

  before_action :get_presentation, except: [:create, :new, :index]

  load_and_authorize_resource

  def index
    # This handles the presentation autocomplete
    @presentations = Presentation.order(:name).includes(:publications, :speakers, :conference => :organizer)
    per_page = params[:per] || 15 # autocomplete specifies :per
    # TODO - what uses autocomplete for presentations?
    if params[:q].present?
      @presentations = @presentations.where("name ILIKE ? OR name ILIKE ?", params[:q] + '%', '% ' + params[:q] + '%').limit(params[:per])
    elsif params[:tag].present?
      # in this case, we want exactly the tagged results
      @presentations  = @presentations.tagged_with(params[:tag])
    elsif params[:search_term].present?
      # Combining these two results ensures that we get both things tagged with the term, as well as things with the term in the name
      presentations_by_tag  = @presentations.tagged_with(params[:search_term])
      presentations_by_name = @presentations.where("name ILIKE ?", "%#{params[:search_term]}%")
      @presentations = presentations_by_tag + (presentations_by_name - presentations_by_tag)
    end
    @presentations = Kaminari.paginate_array(@presentations.to_a).page(params[:page]).per(per_page)

    # The json result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json { render json: { total: @presentations.length, users: @presentations.map{|s| {id: s.id, text: s.name } } } }
    end
  end

  def show
  end

  def edit
  end

  def manage_speakers
    @presentation_speaker = PresentationSpeaker.new
    @current_speaker_ids = @presentation.speakers.map{|s| s.id}.join(',')
  end

  def manage_publications
    @publication = Publication.new
  end

  def new
    # Pre-populate the conference when we're doing the 'create another' flow
    if params[:conference_id]
      @conference = Conference.find(params[:conference_id])
      @presentation = Presentation.new conference_id: @conference.id
    end
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
    if @presentation.update_attributes presentation_params
      redirect_to presentation_path(@presentation)
    else
      flash.now[:error] = 'Your presentation could not be saved.'
      logger.debug "Presentation save failed: #{ @presentation.errors.full_messages }"
      render 'edit'
    end
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
    params.require(:presentation).permit(:conference_id, :speaker_id, :name, :description, :parts, :duration, :tag_list)
  end
end
