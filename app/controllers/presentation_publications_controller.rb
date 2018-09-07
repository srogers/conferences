class PresentationPublicationsController < ApplicationController

  before_action :require_user

  def create
    @presentation_publication = PresentationPublication.new presentation_publication_params
    @presentation_publication.creator_id = current_user.id
    if @presentation_publication.save
      redirect_to manage_publications_presentation_path(@presentation_publication.presentation.to_param)
    else
      flash[:error] = 'The publication/presentation association could not be saved.'
      logger.debug "Presentation Publication save failed: #{ @presentation_publication.errors.full_messages }"
      if @presentation_publication&.presentation_id
        redirect_to manage_publications_presentation_path(@presentation_publication.presentation.to_param)
      else
        redirect_to presentations_path
      end
    end
  end

  def destroy
    @presentation_publication = PresentationPublication.find(params[:id])
    if @presentation_publication
      presentation_id = @presentation_publication.presentation.to_param
      @presentation_publication.destroy
      redirect_to manage_publications_presentation_path(presentation_id)
    else
      render body: nil
    end
  end

  def presentation_publication_params
    params.require(:presentation_publication).permit(:presentation_id, :publication_id)
  end
end
