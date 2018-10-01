module Api
  class PublicationsController < ApiController

    def create
      logger.debug "API publication create"

      # We don't block duplicates here, because publications can have the same name, and we might want to push
      # a publication with a different description when a publication with the same name already exists.

      publication = Publication.create(publication_params.merge(creator_id: current_user.id))

      if publication.errors.empty?
        render :json => { status: "201 created", id: publication.id  }
      else
        render :json => { errors: publication.errors.full_messages }
      end
    end

    private

    def publication_params
      params.require(:publication).permit(:name, :speaker_names, :published_on, :format, :url, :duration, :notes, :editors_notes)
    end

  end
end
