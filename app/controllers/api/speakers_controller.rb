module Api
  class SpeakersController < ApiController

    def show
      speaker = Speaker.friendly.find params[:id]

      if speaker.present?
        render :json => { status: "200 found", id: speaker.id, csrf_token: form_authenticity_token }
      else
        render :json => { status: "404 not found" }
      end
    end

    def create
      logger.debug "API speakers create"

      speaker = Speaker.create(
        name: speaker_params[:name],
        description: speaker_params[:description],
        creator_id: current_user.id
      )

      if speaker.errors.empty?
        render :json => { status: "201 created", id: speaker.id  }
      else
        render :json => { errors: speaker.errors.full_messages }
      end
    end

    def update
      logger.debug "API speakers update"

      # See whether the ID is a number or a slug
      if params["id"] == params["id"].to_i.to_s
        speaker = Speaker.find params["id"]
      else
        speaker = Speaker.friendly.find params["id"]
      end

      if speaker_params[:photo_url].present?
        speaker.remote_photo_url = speaker_params[:photo_url]
      end

      if speaker.present?
        logger.debug "Speaker found."
        status = speaker.update(
          description: speaker_params[:description],
          title:       speaker_params[:title]
        )
        logger.debug "Status: #{ status }"

        if speaker.errors.empty?
          render :json => { status: "204 updated", id: speaker.id  }
        else
          render :json => { errors: speaker.errors.full_messages }
        end
      else
        render :json => { status: "404 not found" }
      end
    end

    private

    def speaker_params
      params.require(:speaker).permit(:name, :photo_url, :description, :title, :company)
    end

  end
end
