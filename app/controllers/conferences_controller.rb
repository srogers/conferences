class ConferencesController < ApplicationController

  before_action :get_conference, except: [:create, :new, :index]
  before_action :get_organizer_selections, only: [:create, :new, :edit]

  load_and_authorize_resource

  def index
    @conferences = Conference.order('start_date DESC').includes(:organizer).references(:organizer)
    per_page = params[:per] || 15 # autocomplete specifies :per
    if params[:search_term].present?
      s = params[:search_term]
      # State-based search is singled out, because the state abbreviations are short, they match many incidental things.
      # This doesn't work for international states - might be fixed by going to country_state_select at some point.
      if s.length == 2 && States::STATES.map{|s| s[0].downcase}.include?(s.downcase)
        @conferences = @conferences.where('conferences.state ILIKE ?', s)
      else
        @conferences = @conferences.where("organizers.name ILIKE ? OR conferences.city ILIKE ? OR conferences.name ILIKE ?", "%#{s}%", "#{s}%", "%#{s}%")
      end
    elsif params[:q].present?
      # autocomplete search - returns most recent conferences until the 4 digit year is complete. Year is the only good unique attribute.
      @conferences = @conferences.where("Extract(year FROM start_date) = ?", params[:q]) if params[:q].present? && params[:q].length == 4
    end
    @conferences = @conferences.page(params[:page]).per(per_page)

    # The JSON result for select2 has to be built with the expected keys
    respond_to do |format|
      format.html
      format.json { render json: { total: @conferences.length, users: @conferences.map{|c| {id: c.id, text: c.name } } } }
    end

  end

  def show
    @conference_user = ConferenceUser.where(conference_id: @conference.id, user_id: current_user&.id).first || ConferenceUser.new
    @presentations = @conference.presentations.order(:name)
  end

  def edit
  end

  def new
  end

  def create
    @conference = Conference.new conference_params
    @conference.city&.strip!
    @conference.state&.strip!
    @conference.creator_id = current_user.id
    if @conference.save
      redirect_to conference_path(@conference)
    else
      flash[:error] = 'Your conference could not be saved.'
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
  end

  def get_organizer_selections
    @organizer_selections = Organizer.all.order(:name).map{|o| ["#{o.name} - #{o.series_name}", o.id]}
  end

  def conference_params
    params.require(:conference).permit(:name, :organizer_id, :program_url, :start_date, :end_date, :venue, :venue_url, :city, :state, :country, :completed)
  end
end
