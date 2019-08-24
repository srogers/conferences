class PresentationsController < ApplicationController

  before_action :get_presentation, except: [:create, :new, :index, :chart, :tags]

  authorize_resource            # friendly_find is incompatible with load_resource

  include SharedQueries         # defines uniform ways for applying search terms
  include PresentationsChart    # gets chart data

  def index
    @presentations = Presentation.includes(:publications, :speakers, :conference => :organizer)
    @presentations = @presentations.order(sort_by_params_or_default 'conferences.start_date DESC, presentations.sortable_name')
    @user_presentations = current_user.user_presentations if current_user.present?
    per_page = params[:per] || 10 # autocomplete specifies :per

    if params[:q].present?
      @presentations = @presentations.where("presentations.name ILIKE ? OR presentations.name ILIKE ?", params[:q] + '%', '% ' + params[:q] + '%').limit(params[:per])
      @presentations = @presentations.where("presentations.id NOT IN (#{params[:exclude].gsub(/[^\d,]/, '')})") if params[:exclude].present?

    elsif params[:search_term].present? || params[:tag].present? || params[:heart].present?
      # This adds onto the search terms, rather than replacing them, so we can search within a Conference, for example.
      if params[:heart].present?
        @presentations = @presentations.includes("taggings").where("taggings.id is null OR coalesce(presentations.description, '') = '' OR presentations.parts IS NULL OR presentations.conference_id is NULL ")
        # Skip conferences in the future - we know they're not done
        @presentations = @presentations.where("conferences.start_date < ?", Date.today)
      end

      # Use wildcards for single and double quote because imported data sometimes has weird characters that don't match regular quote
      term = params[:search_term]&.gsub("'",'_')&.gsub('"','_') || params[:tag]
      @presentations = filter_presentations_by_term(@presentations, term) if term.present?
    end


    @presentations = Kaminari.paginate_array(@presentations.to_a).page(params[:page]).per(per_page)

    # The json result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json do
        if params[:q].present?
          # generate a specific format for select2
          # TODO set up page-specific options for select2,so it can use the generic JSON
          render json: { total: @presentations.length, users: @presentations.map{|s| {id: s.id, text: s.name } } }
        else
          # generate a generic API-like JSON response
          render json: PresentationSerializer.new(@presentations).serialized_json
        end
      end
    end
  end

  # The charts can snag their data from dedicated endpoints, or pass it directly as data - but the height can't be
  # set when using endpoints, so that method is less suitable for charts that vary by the size of the data set (like
  # a vertical bar chart).
  def chart
    case params[:type]
    when 'years' then
      @presentations = presentation_count_data.to_a  # build the data here, or pull it from an endpoint in the JS, but not both
      render 'years_chart'
    when 'topic' then
      @presentations = topic_count_data.sort_by{|topic,count| count }.reverse
      render 'topics_chart'
    else
      flash[:error] = 'Unknown chart type'
      redirect_to presentations_path
    end
  end

  def tags
    @tags = ActsAsTaggableOn::Tag.order(:name)
  end

  def show
  # Pick a path for the Done button that goes back to the context we came from
    if params[:page].present?
      @return_path = presentations_path(helpers.nav_params)                                   # clicked show from conferences listing
    elsif @presentation.conference_id.present?
      @return_path = conference_path(@presentation.conference.to_param, helpers.nav_params)   # clicked show from some other context
    else
      @return_path = presentations_path(helpers.nav_params)
    end

    if current_user
      @user_presentation = current_user.user_presentations.where(presentation_id: @presentation.id).first || UserPresentation.new
    end

    respond_to do |format|
      format.html
      format.json { render json: PresentationSerializer.new(@presentation).serialized_json }
    end
  end

  def edit
    @tags = @presentation.tag_list.join(', ')
  end

  def manage_speakers
    @presentation_speaker = PresentationSpeaker.new
    @current_speaker_ids = @presentation.speakers.map{|s| s.id}.join(',')
  end

  def manage_publications
    @related_publications = Publication.where("name @@  phraseto_tsquery(?)", @presentation.name)
    # Don't add this unless there is something to exclude, because otherwise it makes nothing show up.
    @related_publications = @related_publications.where("publications.id NOT IN (?)", @presentation.presentation_publications.map{|pp| pp.publication_id}) if @presentation.presentation_publications.present?
    @current_publication_ids = @presentation.publications.map{|p| p.id}.join(',')
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
    # When created via the UI, a speaker is required, but the model doesn't require it.
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
    conference = @presentation.conference
    @presentation.destroy

    redirect_to conference.present? ? conference_path(conference) : presentations_path
  end

  private

  def get_presentation
    @presentation = Presentation.friendly.find params[:id]
    redirect_to(@presentation, :status => :moved_permanently) and return if params[:id] != @presentation.slug
  end

  def presentation_params
    params.require(:presentation).permit(:conference_id, :name, :description, :parts, :tag_list, :handout, :remove_handout,
      :editors_notes, :date, :venue, :venue_url, :city, :state, :country)
  end

  def presentation_speaker_params
    params.require(:presentation_speaker).permit(:speaker_id)
  end
end
