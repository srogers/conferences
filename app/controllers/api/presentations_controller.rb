module Api
  class PresentationsController < ApiController

    def create
      logger.debug "API presentation create"

      render :json => { status: "201 created" }
    end
  end
end
