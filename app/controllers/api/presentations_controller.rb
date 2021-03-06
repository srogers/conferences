module Api
  class PresentationsController < ApiController

    def create
      logger.debug "API presentation create"

      # We don't block duplicates here, because presentations can have the same name, and we might want to push
      # a presentation with a different description when a presentation with the same name already exists.

      presentation = Presentation.create(presentation_params.merge(creator_id: current_user.id))

      # The e-store scraper posts a speaker_id, instead of a presentation_speakers => speaker_id
      # There isn't an API method for creating multiple speakers, because there's nothing to use it (yet).
      speaker = Speaker.find params[:speaker_id] rescue false
      if speaker
        PresentationSpeaker.create(presentation_id: presentation.id, speaker_id: speaker.id, creator_id: current_user.id)
      end

      # The speaker isn't taken into account in status - if presentation works, it's all good.
      if presentation.errors.empty?
        render :json => { status: "201 created", id: presentation.id }
      else
        render :json => { errors: presentation.errors.full_messages }
      end
    end

    private

    def presentation_params
      params.require(:presentation).permit(:conference_id, :name, :description, :parts, :tag_list, :handout, :remove_handout, :editors_notes)
    end

  end
end
