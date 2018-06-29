class PublicationsController < ApplicationController

  before_action :require_editor

  def create
    publication = Publication.new publication_params
    publication.creator_id = current_user.id
    unless publication.save
      flash[:error] = 'The publication could not be saved.'
      logger.debug "Publication save failed: #{ publication.errors.full_messages }"
    end
    redirect_to presentation_path(publication.presentation_id)
  end

  def destroy
    publication = Publication.find(params[:id])
    if publication
      presentation_id = publication.presentation_id
      publication.destroy
      redirect_to presentation_path(presentation_id)
    else
      render body: nil
    end
  end

  def publication_params
    params.require(:publication).permit(:presentation_id, :published_on, :format, :url)
  end
end
