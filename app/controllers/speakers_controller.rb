class SpeakersController < ApplicationController

  include PresentationsChart    # defines the filter methods for presentations used when listing speaker presentations
  include Sortability
  include SpeakersChart
  include StickyNavigation

  before_action :check_nav_params, only: [:index]
  before_action :get_speaker, except: [:create, :new, :index, :chart, :presentations_count_by]

  authorize_resource  # friendly_find is incompatible with load_resource

  def index
    @speakers = Speaker.select('speakers.*').order(:sortable_name)

    # This handles the speaker autocomplete from the conference show page. Match first characters of first or last name.
    if params[:q].present?
      @speakers = @speakers.where("name ILIKE ? OR name ILIKE ? ", params[:q] + '%', '% ' + params[:q] + '%')
      @speakers = @speakers.where("speakers.id NOT IN (#{params[:exclude].gsub(/[^\d,]/, '')})") if params[:exclude].present?

      page = 1       # autocomplete should always get page 1 limit 5
      per  = 5
    else
      @speakers = @speakers.includes(:presentations).references(:presentations)
      if params[:heart].present?
        @speakers = @speakers.where("coalesce(speakers.description, '') = '' OR coalesce(speakers.photo, '') = '' ")
      end

      if param_context(:search_term).present?
        @speakers = @speakers.references(:presentations => :conference).includes(:presentations => :conference)
        @speakers = filter_speakers @speakers
      end

      page = param_context(:page)
      per  = param_context(:per)
    end

    @speakers = @speakers.page(page).per(per)

    # The JSON result has to be built with the keys in the data expected by select2
    respond_to do |format|
      format.html
      format.json { render json: { total: @speakers.length, users: @speakers.map{|s| {id: s.id, text: s.name } } } }
    end
    repaginate_if_needed(@speakers)
  end

  def chart
    # The charts can snag their data from dedicated endpoints, or pass it directly as data - but the height can't be
    # set when using endpoints, so that method is less suitable for charts that vary by the size of the data set (like
    # a vertical bar chart).
    case param_context(:chart_type)
    when 'presentations' then
      @presentations = speaker_presentation_count_data.to_a    # build the data here, or pull it from an endpoint in the JS, but not both
      render 'presentations_chart'
    when 'conferences' then
      @conferences = conference_count_data.to_a
      render 'conferences_chart'
    else
      flash[:error] = 'Unknown chart type'
      redirect_to speakers_path
    end
  end

  # Feeds the frequent speakers chart - the name gives presentations_count_by_speakers_path
  # Speakers are the thing being counted - which is why it's here, and not in conferences controller (although the search terms are similar)
  def presentations_count_by

    respond_to do |format|
      format.html
      format.json { render json: speaker_count_data.to_json }
    end
  end

  def show
    @presentations = @speaker.presentations.includes(:conference, :publications, :speakers).references(:conference)
    @presentations = @presentations.order(params_to_sql '<presentations.date')

    # TODO - see if there is a way to get this with an additional include
    @user_presentations = current_user.user_presentations if current_user.present?

    # Here we just filter presentations, and skip all the business presentations controller does with :q and :hear params
    if param_context(:search_term).present? || param_context(:tag).present? || param_context(:event_type).present?
      @presentations = filter_presentations @presentations
    end

    respond_to do |format|
      format.html
      format.json { render json: @speaker, status: :ok }
    end
  end

  def edit
  end

  def new
    @speaker = Speaker.new
  end

  def create
    @speaker = Speaker.new speaker_params
    @speaker.name.strip!
    @speaker.creator_id = current_user.id
    if @speaker.save
      redirect_to speaker_path(@speaker)
    else
      flash.now[:error] = "Your speaker could not be saved: #{ @speaker.errors.full_messages.join(", ") }"
      logger.error "Speaker save failed: #{ @speaker.errors.full_messages.join(", ") }"
      render 'new'
    end
  end

  def update
    if @speaker.update_attributes speaker_params
      redirect_to speaker_path(@speaker)
    else
      flash.now[:error] = "Your changes could not be saved: #{ @speaker.errors.full_messages.join(', ') }"
      logger.error "Speaker update failed: #{ @speaker.errors.full_messages.join(', ') }"
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
    redirect_to(@speaker, :status => :moved_permanently) and return if params[:id] != @speaker.slug
  end

  def speaker_params
    params.require(:speaker).permit(:name, :description, :title, :bio_url, :bio_on, :photo, :remove_photo, :sortable_name)
  end
end
