class ConferencesController < ApplicationController

  before_action :get_conference, except: [:create, :new, :index, :cities_chart, :countries_chart, :years_chart, :cities_count_by]
  before_action :get_organizer_selections, only: [:create, :new, :edit]

  authorize_resource  # friendly_find is incompatible with load_resource

  include ConferencesChart
  include SpeakersChart
  include ConferencesHelper

  def index
    @conferences = Conference.order('start_date DESC').includes(:organizer)
    per_page = params[:per] || 15 # autocomplete specifies :per
    if params[:search_term].present? || params[:heart].present?
      if params[:heart].present?
        @conferences = @conferences.where("NOT completed AND conferences.start_date < ?", Date.today)
      end

      if params[:search_term].present?
        term = params[:search_term]
        # State-based search is singled out, because the state abbreviations are short, they match many incidental things.
        # This doesn't work for international states - might be fixed by going to country_state_select at some point.
        if term.length == 2 && States::STATES.map{|term| term[0].downcase}.include?(term.downcase)
          @conferences = @conferences.where('conferences.state ILIKE ?', term)
        else
          @conferences = @conferences.where(base_query, "#{term}%", "#{term}%", country_code(term), "#{term}", "#{term}%" )
        end
      end
    elsif params[:q].present?
      # Presentations uses this for picking conference in case where a presentation is created without a conference, then associated later.
      # Returns most recent conferences until the 4 digit year is complete. Year is the only good attribute for ensuring
      # the target conference will show up within a set of 5. Over time, may need to bump the 5 to 6 or 8 - use conferences_by_year
      # chart - value needs to be =< maximum conferences in any one year.
      @conferences = @conferences.where("Extract(year FROM start_date) = ?", params[:q]) if params[:q].present? && params[:q].length == 4
      @conferences = @conferences.limit(7)
    end
    @conferences = @conferences.page(params[:page]).per(per_page)

    # The JSON result for select2 has to be built with the expected keys
    respond_to do |format|
      format.html
      format.json { render json: { total: @conferences.length, users: @conferences.map{|c| {id: c.id, text: c.name } } } }
    end
  end

  # The charts can snag their data from dedicated endpoints, or pass it directly as data - but the height can't be
  # set when using endpoints, so that method is less suitable for charts that vary by the size of the data set (like
  # a vertical bar chart).
  def cities_chart
    @cities = city_count_data.to_a      # build the data here, or pull it from an endpoint in the JS, but not both
  end

  def countries_chart
    @countries = country_count_data.to_a      # build the data here, or pull it from an endpoint in the JS, but not both
  end

  def years_chart
    @years = year_count_data.to_a
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
    @presentations = @conference.presentations.order("presentations.sortable_name")
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
      redirect_to conference_path(@conference)
    else
      flash.now[:error] = 'Your conference could not be saved.'
      get_organizer_selections
      logger.debug "Conference save failed: #{ @conference.errors.full_messages }"
      render 'new'
    end
  end

  def update
    if @conference.update_attributes conference_params
      redirect_to conference_path(@conference)
    else
      flash.now[:error] = 'Your conference could not be saved.'
      get_organizer_selections
      logger.debug "Conference save failed: #{ @conference.errors.full_messages }"
      render 'edit'
    end
  end

  def destroy
    if can?(:destroy, @conference) && @conference.presentations.empty?
      @conference.destroy
    else
      flash[:notice] = "That conference can't be deleted because it has presentations linked to it."
    end

    redirect_to conferences_path
  end

  private

  def get_conference
    @conference = Conference.friendly.find params[:id]
    redirect_to(@conference, :status => :moved_permanently) and return if params[:id] != @conference.slug
  end

  def get_organizer_selections
    # JS on the conference create page parses the organizer abbreviation out of this
    @organizer_selections = Organizer.all.order(:name).map{|o| ["#{o.name} - #{o.series_name} - #{o.abbreviation}", o.id]}
  end

  def conference_params
    params.require(:conference).permit(:name, :organizer_id, :program_url, :start_date, :end_date, :venue, :venue_url, :city, :state, :country, :completed, :editors_notes)
  end
end
