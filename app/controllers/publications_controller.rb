class PublicationsController < ApplicationController

  include PublicationsChart         # defines uniform ways for applying search terms
  include StickyNavigation

  before_action :check_nav_params, only: [:index]
  before_action :get_publication, except: [:index, :create, :new, :chart, :latest]

  authorize_resource

  def index
    @publications = Publication
    # Patch a recurring error in Sentry
    if params[:sort] == '-created_at'
      logger.warn "patching over invalid params"
      redirect_to publications_path(sort: '-publications.created_at') and return
    end

    if params[:q].present? # then it's autocomplete
      @publications = @publications.where("publications.name ILIKE ? OR publications.name ILIKE ?", "#{params[:q]}%", "% #{params[:q]}%").limit(param_context(:per))
      @publications = @publications.where("publications.id NOT IN (#{params[:exclude].gsub(/[^\d,]/, '')})") if params[:exclude].present?

    else
      @publications = publication_collection

      if params[:heart].present?
        # Jam this clause in as a special case - it's just an admin/editor helper. has nothing to do with the data,
        # so it shouldn't ever get into charts
        @publications = @publications.where("
          publications.published_on IS NULL OR (publications.duration IS NULL AND publications.format IN (?)) OR
          (SELECT COUNT(*) FROM presentation_publications pp WHERE pp.publication_id = publications.id) < 1
        ", Publication::HAS_DURATION)
      end

      if param_context(:search_term).present?
        @publications = filter_publications @publications
      end
    end

    # The listing contains "duplicates" - the same publication name in various formats, so the listing makes more sense
    # if these alternate formats always appear together. To do that, we add it as a secondary sort when it isn't the primary
    sorting = params_to_sql('<publications.published_on')
    sorting = [sorting, 'publications.name ASC'].compact.join(', ') unless sorting&.include?('publications.name')
    @publications = @publications.order(Arel.sql(sorting))

    page = params[:q].present? ? 1 : param_context(:page)       # autocomplete should always get page 1 limit 8
    per  = params[:q].present? ? 8 : param_context(:per)

    @publications = @publications.page(page).per(per)

    respond_to do |format|
      format.html
      format.json do
        if params[:q].present?
          # generate a specific format for select2
          # TODO set up page-specific options for select2,so it can use the generic JSON
          render json: { total: @publications.length, users: @publications.map{|p| {id: p.id, text: "#{ p.name } (#{ p.format }) (#{ p.published_on })" } } }
        else
          format.json { render json: PublicationSerializer.new(@publications).serialized_json }
        end
      end
    end
    repaginate_if_needed(@publications)
  end

  def latest
    @publications = Publication.includes(:presentations => :speakers).order(Arel.sql('publications.created_at DESC')).limit(3)
    render layout: false
  end

  def chart
    case param_context(:chart_type)
    when 'format' then
      @formats = format_count_data.to_a      # build the data here, or pull it from an endpoint in the JS, but not both
      render 'formats_chart'
    when 'year' then
      @publications = publication_year_count_data.to_a
      render 'years_chart'
    when 'duration_year' then
      @publications = publication_duration_year_count_data.to_a
      render 'duration_by_year_chart'
    when 'publisher' then
      @publishers = publication_publishers_count_data.to_a
      render 'publishers_chart'
    else
      flash[:error] = 'Unknown chart type'
      redirect_to publications_path
    end
  end

  def show
    @related_presentations = Presentation.where("name @@  phraseto_tsquery(?)", @publication.name)
    # Don't add this unless there is something to exclude, because otherwise it makes nothing show up.
    @related_presentations = @related_presentations.where("presentations.id NOT IN (?)", @publication.presentation_publications.map{|pp| pp.presentation_id}) if @publication.presentation_publications.present?
    @current_presentation_ids = @publication.presentations.map{|p| p.id}.join(',')

    respond_to do |format|
      format.html
      format.json { render json: PublicationSerializer.new(@publication).serialized_json }
    end
  end

  def new
    @publishers = Publisher.all.map{|p| [p.name]}
    @languages = Language.all.map{|l| [l.name, l.id]}
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
        @presentation_publication = PresentationPublication.create presentation_id: @presentation.id, publication_id: @publication.id, creator_id: current_user.id, canonical: params[:canonical] == 'true'
        redirect_to manage_publications_presentation_path(@presentation)
      else
        redirect_to publication_path(@publication)
      end
    else
      @languages = Language.all.map{|l| [l.name, l.id]}
      flash[:error] = "The publication could not be saved: #{ @publication.errors.full_messages.join(', ') }"
      logger.error "Publication save failed: #{ @publication.errors.full_messages }"
      render 'new'
    end
  end

  def edit
    @languages = Language.all.map{|l| [l.name, l.id]}
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
      @languages = Language.all.map{|l| [l.name, l.id]}
      flash.now[:error] = "Your publication could not be saved: #{ @publication.errors.full_messages.join(', ') }"
      logger.error "Publication update failed: #{ @publication.errors.full_messages }"
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
    @publishers  = Publisher.all.map{|p| [p.name]}
    @publication = Publication.find params[:id]
    get_presentation
  end

  def publication_params
    params.require(:publication).permit(
      :name, :speaker_names, :published_on, :format, :url, :duration, :ui_duration, :publisher, :ari_inventory, :details,
      :notes, :editors_notes, :language_id
    )
  end
end
