class PublicationsController < ApplicationController

  before_action :require_editor
  before_action :get_publication, except: [:create, :new]

  authorize_resource

  def create
    @publication = Publication.new publication_params
    @publication.creator_id = current_user.id
    if @publication.save
      redirect_to manage_publications_presentation_path(@publication.presentation_id)
    else
      flash[:error] = 'The publication could not be saved.'
      logger.debug "Publication save failed: #{ @publication.errors.full_messages }"
      redirect_to presentations_path
    end
  end

  def edit
    @presentation = @publication.presentation
  end

  def update
    if @publication.update_attributes publication_params
      redirect_to manage_publications_presentation_path(@publication.presentation_id)
    else
      flash.now[:error] = 'Your publication could not be saved.'
      logger.debug "Publication save failed: #{ @publication.errors.full_messages }"
      @presentation = @publication.presentation
      render 'edit'
    end
  end

  def destroy
    if @publication
      presentation_id = @publication.presentation_id
      @publication.destroy
      redirect_to manage_publications_presentation_path(presentation_id)
    else
      render body: nil
    end
  end

  def get_publication
    @publication = Publication.find params[:id]
  end

  def publication_params
    params.require(:publication).permit(:presentation_id, :published_on, :format, :url, :duration, :notes)
  end
end
