class EventsController < ApplicationController

  include ConferencesChart
  include ConferencesHelper
  include Sortability
  include SpeakersChart
  include StickyNavigation

  before_action :check_nav_params, only: [:index]
  before_action :get_conference, except: [:create, :new, :index, :chart, :upcoming, :cities_count_by]
  before_action :get_organizer_selections, only: [:create, :new, :edit]

  authorize_resource :conference  # friendly_find is incompatible with load_resource

  def index
    @conferences = Conference

    # This structure separates out the :q from everything else. TODO maybe put autocomplete in a separate action
    if params[:q].present?
      # Presentations uses this for picking event in case where a presentation is created without an event, then associated later.
      # Allows search by year or name segment. This is tricky because so many events have nearly the same name.
      if params[:q].length == 4
        @conferences = @conferences.where("Extract(year FROM start_date) = ?", params[:q])
      else
        @conferences = @conferences.where("conferences.name ILIKE ?", '%' + params[:q] + '%')
      end

      page = 1       # autocomplete should always get page 1 limit 8
      per  = 8
    else
      # Set up a complex WHERE but select only conferences
      @conferences = @conferences.select('conferences.*').includes(:presentations => :publications ).references(:presentations => :publications ).order(params_to_sql('<conferences.start_date'))

      if params[:heart].present?
        @conferences = @conferences.where("NOT completed AND conferences.start_date < ?", Date.today)
      end
      if param_context(:search_term).present? || param_context(:event_type).present?
        @conferences = filter_events @conferences
      end

      page = param_context(:page)
      per  = param_context(:per)
    end

    @conferences = @conferences.page(page).per(per)

    # The JSON result for select2 has to be built with the expected keys
    respond_to do |format|
      format.html
      format.json { render json: { total: @conferences.length, users: @conferences.map{|c| {id: c.id, text: c.name } } } }
    end
    repaginate_if_needed(@conferences)
  end

  # This is a lot like a subset of index, but the layout is quite different, so merging it into one action is tedious.
  # Gets called from jQuery in /news and rendered by jQuery append(html).
  def upcoming
    @conferences = Conference.where("conferences.start_date > ?", Date.today).order('start_date ASC')
    render layout: false
  end

  # The charts can snag their data from dedicated endpoints, or pass it directly as data - but the height can't be
  # set when using endpoints, so that method is less suitable for charts that vary by the size of the data set (like
  # a vertical bar chart).
  def chart
    case param_context(:chart_type)
    when 'cities' then
      @cities = city_count_data.to_a            # build the data here, or pull it from an endpoint in the JS, but not both
      render 'cities_chart'
    when 'countries' then
      @countries = country_count_data.to_a      # build the data here, or pull it from an endpoint in the JS, but not both
      render 'countries_chart'
    when 'years' then
      @years = year_count_data.to_a
      render 'years_chart'
    else
      flash[:error] = 'Unknown chart type'
      redirect_to events_path
    end
  end

  # Feeds the frequent cities chart
  def cities_count_by

    respond_to do |format|
      format.html
      format.json { render json: city_count_data.to_json }
    end
  end

  def show
    @conference_user = ConferenceUser.where(conference_id: @conference.id, user_id: current_user&.id).first || ConferenceUser.new
    default_sorting = (@conference.virtual? || @conference.multi_venue?) ? ">presentations.date" : ">presentations.sortable_name"
    @presentations = @conference.presentations.order(params_to_sql default_sorting)
    @user_presentations = current_user.user_presentations if current_user.present?
  end

  def edit
    # Keep custom names - but dynamically change the name based on date/organizer if it's still the default name
    gon.apply_name_default = name_blank_or_default?(@conference)
  end

  def new
    gon.apply_name_default = true
    @conference = Conference.new
  end

  def create
    @conference = Conference.new conference_params
    @conference.city&.strip!
    @conference.state&.strip!
    @conference.creator_id = current_user.id
    if @conference.save
      redirect_to event_path(@conference)
    else
      flash.now[:error] = "Your event could not be saved: #{ @conference.errors.full_messages.join(', ') }"
      get_organizer_selections
      logger.error "Event save failed: #{ @conference.errors.full_messages.join(', ') }"
      render 'new'
    end
  end

  def update
    if @conference.update_attributes conference_params
      redirect_to event_path(@conference)
    else
      flash.now[:error] = "Your event could not be saved: #{ @conference.errors.full_messages.join(', ') }"
      get_organizer_selections
      logger.error "Event update failed: #{ @conference.errors.full_messages.join(', ') }"
      render 'edit'
    end
  end

  def destroy
    if can?(:destroy, @conference) && @conference.presentations.empty?
      @conference.destroy
    else
      flash[:notice] = "That event can't be deleted because it has presentations linked to it."
    end

    redirect_to events_path
  end

  private

  def get_conference
    @conference = Conference.friendly.find params[:id]
    redirect_to(event_path(@conference, :status => :moved_permanently)) and return if params[:id] != @conference.slug
  end

  def get_organizer_selections
    # JS on the conference create page parses the organizer abbreviation out of this
    @organizer_selections = Organizer.all.order(:name).map{|o| ["#{o.name} - #{o.series_name} - #{o.abbreviation}", o.id]}
  end

  def conference_params
    params.require(:conference).permit(
      :name, :event_type, :description, :organizer_id, :registration_url, :start_date, :end_date,
      :venue, :venue_url, :city, :state, :country, :completed, :editors_notes
    )
  end
end
