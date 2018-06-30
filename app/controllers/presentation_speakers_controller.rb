class PresentationSpeakersController < ApplicationController

  before_action :require_user

  def create
    presentation_speaker = PresentationSpeaker.new presentation_speaker_params
    presentation_speaker.creator_id = current_user.id
    if presentation_speaker.save
      redirect_to presentation_path(presentation_speaker.presentation_id)
    else
      flash[:error] = 'The speaker/presentation association could not be saved.'
      logger.debug "Presentation Speaker save failed: #{ presentation_speaker.errors.full_messages }"
      redirect_to presentations_path
    end
  end

  def destroy
  end

  def presentation_speaker_params
    params.require(:presentation_speaker).permit(:presentation_id, :speaker_id)
  end
end
