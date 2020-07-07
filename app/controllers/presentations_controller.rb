class PresentationsController < ApplicationController

  include PresentationsChart    # defines the filter methods and gets chart data
  include StickyNavigation

  before_action :check_nav_params, only: [:index]
  before_action :get_presentation, except: [:create, :new, :index, :chart, :tags]

  authorize_resource            # friendly_find is incompatible with load_resource

  def index
    if params[:sort] == '-created_at'
      logger.warn "patching over invalid params"
      redirect_to presentations_path(sort: '-presentations.created_at') and return
    end

    # Construct the simplest query base for guest user (and robots) - build elaborate WHERE, but only fetch presentations.
    @presentations = Presentation.select('presentations.*').includes(:conference, :publications, :speakers).references(:conference)

    @presentations = @presentations.order(params_to_sql Arel.sql('<presentations.date'))
    # This is necessary for getting the presentation status - TODO see if it can be fetched via association
    @user_presentations = current_user.user_presentations if current_user.present?

    if params[:q].present?
      # Then it's an autocomplete query
      @presentations = @presentations.where("presentations.name ILIKE ? OR presentations.name ILIKE ?", params[:q] + '%', '% ' + params[:q] + '%').limit(param_context(:per))
      @presentations = @presentations.where("presentations.id NOT IN (#{params[:exclude].gsub(/[^\d,]/, '')})") if params[:exclude].present?

    else
      # "heart" adds onto the search terms, rather than replacing them, so we can search within a Conference, for example.
      if params[:heart].present?
        # TODO - should this include presentations without tags?  Seems like not - probably not a goal to tag *every* one.
        @presentations = @presentations.where("coalesce(presentations.description, '') = '' OR presentations.parts IS NULL OR presentations.conference_id is NULL ")
        # Skip conferences in the future - we know they're not done
        @presentations = @presentations.where("conferences.start_date < ?", Date.today)
      end

      if param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
        @presentations = filter_presentations @presentations
      end
    end

    page = params[:q].present? ? 1 : param_context(:page)       # autocomplete should always get page 1 limit 8
    per  = params[:q].present? ? 8 : param_context(:per)
    @presentations = @presentations.page(page).per(per)

    # The json result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json do
        if params[:q].present?
          # generate a specific format for select2
          # TODO set up page-specific options for select2,so it can use the generic JSON
          render json: { total: @presentations.length, users: @presentations.map{|s| {id: s.id, text: "#{s.name} (#{ s.date.year })" } } }
        else
          # generate a generic API-like JSON response
          render json: PresentationSerializer.new(@presentations).serialized_json
        end
      end
    end
    repaginate_if_needed(@presentations)
  end

  # The charts can snag their data from dedicated endpoints, or pass it directly as data - but the height can't be
  # set when using endpoints, so that method is less suitable for charts that vary by the size of the data set (like
  # a vertical bar chart).
  def chart
    case param_context(:chart_type)
    when 'years' then
      @presentations = presentation_count_data.to_a  # build the data here, or pull it from an endpoint in the JS, but not both
      render 'years_chart'
    when 'topics' then
      @presentations = topic_count_data.sort_by{|topic,count| count }.reverse
      render 'topics_chart'
    when 'speakers' then
      @speakers = speaker_count_data.sort_by{|topic,count| count }.reverse
      render 'speakers_chart'
    else
      flash[:error] = 'Unknown chart type'
      redirect_to presentations_path
    end
  end

  def tags
    @tags = ActsAsTaggableOn::Tag.order(Arel.sql('LOWER(name)'))
    if params[:term].present?
      @tags = @tags.where("LOWER(name) LIKE ?", '%' + params[:term].downcase + '%')
    end

    # The returned JSON needs to be in the format: [{"id":"Platalea leucorodia","label":"Spoonbill","value":"Spoonbill"}]
    # with no top level key (which is not documented anywhere).  If it's not right, you'll get "no data returned"
    respond_to do |format|
      format.html                                                                               # show the user the tag list
      format.json { render json:  @tags.map{|t| { id: t.id, label: t.name, value: t.name } } }  # Autocomplete input
    end
  end

  def show
    if current_user
      @user_presentation = current_user.user_presentations.where(presentation_id: @presentation.id).first || UserPresentation.new
    end

    respond_to do |format|
      format.html { params[:details].present? ? render('presentations/details', layout: false) : render('show') } # details responds to an ajax action on the index page
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
    @publishers  = Publisher.all.map{|p| [p.name]}
    @related_publications = Publication.where("name @@  phraseto_tsquery(?)", @presentation.name)
    # Don't add this unless there is something to exclude, because otherwise it makes nothing show up.
    @related_publications = @related_publications.where("publications.id NOT IN (?)", @presentation.presentation_publications.map{|pp| pp.publication_id}) if @presentation.presentation_publications.present?
    @current_publication_ids = @presentation.publications.map{|p| p.id}.join(',')
    @publication = Publication.new published_on: Date.today
  end

  # Send the handout straight to the browser - assumes PDF is required at upload
  def download_handout
    send_data @presentation.handout.read, type: 'application/pdf', disposition: 'inline', filename: "handout.pdf"
  end

  def new
    # Pre-populate the event-related fields when the presentation is created in the context of an event
    @speaker = Speaker.new
    if params[:conference_id]
      @conference = Conference.find(params[:conference_id])
      # Set the conference ID, plus inherit any of these that may show up in the form now or later.
      @presentation = Presentation.new conference_id: @conference.id
      @presentation.inherit_conference_defaults
    else
      @presentation = Presentation.new
    end
  end

  def create
    @presentation = Presentation.new presentation_params
    @presentation.inherit_conference_defaults
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
      logger.error "Presentation save failed: #{ @presentation.errors.full_messages.join(', ') }"
      logger.debug @speaker.inspect
      render 'new'
    end
  end

  def update
    if @presentation.update_attributes presentation_params
      redirect_to presentation_path(@presentation)
    else
      flash.now[:error] = "Your presentation could not be saved: #{ @presentation.errors.full_messages.join(', ') }"
      logger.error "Presentation update failed: #{ @presentation.errors.full_messages.join(', ') }"
      render 'edit'
    end
  end

  def destroy
    conference = @presentation.conference
    @presentation.destroy

    redirect_to conference.present? ? event_path(conference) : presentations_path
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
