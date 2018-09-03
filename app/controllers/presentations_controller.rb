class PresentationsController < ApplicationController

  before_action :get_presentation, except: [:create, :new, :index, :chart, :tags]

  authorize_resource            # friendly_find is incompatible with load_resource

  include SharedQueries         # defines uniform ways for applying search terms
  include PresentationsChart    # gets chart data

  def index
    @presentations = Presentation.includes(:publications, :speakers, :conference => :organizer).order('conferences.start_date DESC, presentations.sortable_name')
    per_page = params[:per] || 15 # autocomplete specifies :per

    # TODO - what uses autocomplete for presentations?
    if params[:q].present?
      @presentations = @presentations.where("presentations.name ILIKE ? OR presentations.name ILIKE ?", params[:q] + '%', '% ' + params[:q] + '%').limit(params[:per])

    elsif params[:search_term].present? || params[:tag].present?
      term = params[:search_term] || params[:tag]
      @presentations = filter_presentations_by_term(@presentations, term)
    end

    @presentations = Kaminari.paginate_array(@presentations.to_a).page(params[:page]).per(per_page)

    # The json result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json { render json: { total: @presentations.length, users: @presentations.map{|s| {id: s.id, text: s.name } } } }
    end
  end

  def chart
    # The charts can snag their data from dedicated endpoints, or pass it directly as data - but the height can't be
    # set when using endpoints, so that method is less suitable for charts that vary by the size of the data set (like
    # a vertical bar chart).
    @presentations = presentation_count_data.to_a  # build the data here, or pull it from an endpoint in the JS, but not both
  end

  def tags
    @tags = ActsAsTaggableOn::Tag.order(:name)
  end

  def show
  end

  def edit
    @tags = @presentation.tag_list.join(', ')
  end

  def manage_speakers
    @presentation_speaker = PresentationSpeaker.new
    @current_speaker_ids = @presentation.speakers.map{|s| s.id}.join(',')
  end

  def manage_publications
    @publication = Publication.new
  end

  # Send the handout straight to the browser - assumes PDF is required at upload
  def download_handout
    send_data @presentation.handout.read, type: 'application/pdf', disposition: 'inline', filename: "handout.pdf"
  end

  def new
    # Pre-populate the conference when we're doing the 'create another' flow
    @speaker = Speaker.new
    if params[:conference_id]
      @conference = Conference.find(params[:conference_id])
      @presentation = Presentation.new conference_id: @conference.id
    else
      @presentation = Presentation.new
    end
  end

  def create
    @presentation = Presentation.new presentation_params
    if presentation_speaker_params[:speaker_id].blank?
      flash.now[:error] = "Presentations require at least one speaker"
      render 'new' and return
    end

    @speaker = Speaker.find params[:presentation_speaker][:speaker_id] rescue false
    unless @speaker
      # Seems like this would have to be params hackery, or a bug
      flash.now[:error] = "Couldn't find that speaker - contact an admin for assistance"
      logger.warn "Presentation create got a post from user #{current_user.id} with non-existent speaker ID #{ params[:presentation_speaker][:speaker_id] }"
      render 'new' and return
    end

    @presentation.name.strip!
    @presentation.creator_id = current_user.id
    if @presentation.save
      if params[:presentation_speaker].present?
        PresentationSpeaker.create(presentation_id: @presentation.id, speaker_id: @speaker.id, creator_id: current_user.id)
      end
      redirect_to presentation_path(@presentation)
    else
      flash.now[:error] = "Your presentation could not be saved: #{ @presentation.errors.full_messages.join(', ') }"
      logger.debug "Presentation save failed: #{ @presentation.errors.full_messages.join(', ') }"
      logger.debug @speaker.inspect
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
    @presentation = Presentation.friendly.find params[:id]
    redirect_to(@presentation, :status => :moved_permanently) and return if params[:id] != @presentation.slug
  end

  def presentation_params
    params.require(:presentation).permit(:conference_id, :name, :description, :parts, :tag_list, :handout, :remove_handout, :editors_notes)
  end

  def presentation_speaker_params
    params.require(:presentation_speaker).permit(:speaker_id)
  end
end
