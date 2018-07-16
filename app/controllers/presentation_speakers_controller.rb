class PresentationSpeakersController < ApplicationController

  before_action :require_user

  def create
    @presentation_speaker = PresentationSpeaker.new presentation_speaker_params
    @presentation_speaker.creator_id = current_user.id
    if @presentation_speaker.save
      redirect_to manage_speakers_presentation_path(@presentation_speaker.presentation_id)
    else
      flash[:error] = 'The speaker/presentation association could not be saved.'
      logger.debug "Presentation Speaker save failed: #{ presentation_speaker.errors.full_messages }"
      if @presentation_speaker&.presentation_id
        redirect_to manage_speakers_presentation_path(@presentation_speaker.presentation_id)
      else
        redirect_to presentations_path
      end
    end
  end

  def destroy
    @presentation_speaker = PresentationSpeaker.find(params[:id])
    if @presentation_speaker
      presentation_id = @presentation_speaker.presentation_id
      @presentation_speaker.destroy
      redirect_to manage_speakers_presentation_path(presentation_id)
    else
      render body: nil
    end
  end

  def presentation_speaker_params
    params.require(:presentation_speaker).permit(:presentation_id, :speaker_id)
  end
end
