class ConferenceSpeakersController < ApplicationController

  before_action :require_user

  def create
    conference_speaker = ConferenceSpeaker.new conference_speaker_params
    conference_speaker.creator_id = current_user.id
    unless conference_speaker.save
      flash[:error] = 'The speaker/conference association could not be saved.'
      logger.debug "Conference Speaker save failed: #{ conference_speaker.errors.full_messages }"
    end
    redirect_to conference_path(conference_speaker.conference_id)
  end

  def destroy
  end

  def conference_speaker_params
    params.require(:conference_speaker).permit(:conference_id, :speaker_id)
  end
end
