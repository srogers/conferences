class PublicationsController < ApplicationController

  before_action :get_publication, except: [:index, :create, :new, :chart]

  authorize_resource

  include PublicationsChart         # defines uniform ways for applying search terms

  def index
    per_page = params[:per] || 10 # autocomplete specifies :per
    @publications = Publication.includes(:presentations => { :conference => :organizer } ).includes(:presentations => :speakers).order('publications.name')  #order('conferences.start_date DESC')

    if params[:heart].present?
      @publications = @publications.where("
        publications.published_on IS NULL OR (publications.duration IS NULL AND publications.format IN (?)) OR
        (SELECT COUNT(*) FROM presentation_publications pp WHERE pp.publication_id = publications.id) < 1
      ", Publication::HAS_DURATION)
    end

    if params[:search_term].present?
      term = params[:search_term]
      @publications = @publications.references(:conferences)
      # State-based search is singled out, because the state abbreviations are short, they match many incidental things.
      # This doesn't work for international states - might be fixed by going to country_state_select at some point.
      if term.length == 2 && States::STATES.map{|term| term[0].downcase}.include?(term.downcase)
        @publications = @publications.where('conferences.state = ?', term.upcase)
      else
        @publications = @publications.where(base_query + ' OR publications.name ILIKE ? OR publications.format ILIKE ? OR speakers.name ILIKE ? OR speakers.sortable_name ILIKE ?', "#{term}%", "%#{term}%", country_code(term), "#{term}", "#{term}%", "%#{term}%", "#{term}%", "#{term}%", "#{term}%")
      end
    end

    @publications = @publications.page(params[:page]).per(per_page)

    # The JSON result has to be built with the keys in the data expected by select2 for autocomplete
    respond_to do |format|
      format.html
      format.json { render json: PublicationSerializer.new(@publications).serialized_json }
    end
  end

  def chart
    case params[:type]
    when 'format' then
      @formats = format_count_data.to_a      # build the data here, or pull it from an endpoint in the JS, but not both
      render 'formats_chart'
    else
      flash[:error] = 'Unknown chart type'
      redirect_to publications_path
    end
  end

  def show
    @related_presentations = Presentation.where("name @@  phraseto_tsquery(?)", @publication.name)
    # Don't add this unless there is something to exclude, because otherwise it makes nothing show up.
    @related_presentations = @related_presentations.where("presentations.id NOT IN (?)", @publication.presentation_publications.map{|pp| pp.presentation_id}) if @publication.presentation_publications.present?
  end

  def new
    @publication = Publication.new
  end

  # Creates a Publication and allows a Presentation/Publication relationship to be created simultaneously by passing a presentation ID
  def create
    get_presentation
    @publication = Publication.new publication_params
    @publication.creator_id = current_user.id
    if @presentation.present? # The user doesn't see name or speaker names in the Manage Publications context
      @publication.name ||= @presentation.name
      @publication.speaker_names = 'N/A'        # something meaningful to show Editors when looking at publication details regular users can't see
    end
    if @publication.save
      if @presentation.present?
        @presentation_publication = PresentationPublication.create presentation_id: @presentation.id, publication_id: @publication.id, creator_id: current_user.id, canonical: params[:canonical].present?
        redirect_to manage_publications_presentation_path(@presentation)
      else
        redirect_to publication_path(@publication)
      end
    else
      flash[:error] = 'The publication could not be saved.'
      logger.debug "Publication save failed: #{ @publication.errors.full_messages }"
      redirect_to presentations_path
    end
  end

  def edit
    @publication.name ||= @presentation.name if @presentation.present?
  end

  def update
    # Backfill these values on legacy presentations
    @publication.name ||= @presentation&.name || 'N/A'
    @publication.speaker_names ||= 'N/A'        # something meaningful to show Editors when looking at publication details regular users can't see

    if @publication.update_attributes publication_params
      if @presentation.present?
        if params[:canonical].present? # then update this attribute of the relationship
          @presentation_publication = PresentationPublication.where(presentation_id: @presentation.id, publication_id: @publication.id).first
          if @presentation_publication
            @presentation_publication.update_attribute(:canonical, params[:canonical] == "true")
          else
            logger.error "publication#update expected to find PresentationPublication with presentation_id: #{@presentation.id}, publication_id: #{@publication.id} but didn't."
          end
        end
        redirect_to manage_publications_presentation_path(@presentation)
      else
        redirect_to publication_path(@publication)
      end
    else
      flash.now[:error] = 'Your publication could not be saved.'
      logger.debug "Publication save failed: #{ @publication.errors.full_messages }"
      render 'edit'
    end
  end

  def destroy
    @publication.destroy
    # Manage Publications passes the publication ID so we can get back to the origin page
    if @presentation.present?
      redirect_to manage_publications_presentation_path(@presentation)
    else
      redirect_to publications_path
    end
  end

  # Create, update, edit and destroy use presentation to get back to manage_presentations when we came from there.
  def get_presentation
    if params[:presentation_id].present?
      @presentation = Presentation.find params[:presentation_id]
    end
  end

  def get_publication
    @publication = Publication.find params[:id]
    get_presentation
  end

  def publication_params
    params.require(:publication).permit(:name, :speaker_names, :published_on, :format, :url, :duration, :notes, :editors_notes)
  end
end
