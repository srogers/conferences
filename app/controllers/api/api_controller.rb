module Api
  # Actions that get data open to the public respond with JSON on the normal routes.
  # The API handles only creates/updates requiring auth.

  class ApiController < ActionController::Base

    protect_from_forgery with: :null_session              # Prevents the API from being locked down by CSRF checks
    before_action       :require_http_auth_user           # Use HTTP Basic Auth instead of standard auth

    def current_user
      defined?(@current_user) ? @current_user : nil
    end

    # Returns a string something like the one generated by Friendly_ID - maybe not exactly the algorithm, but close enough.
    def sluggify(name)
      name.downcase.tr('^a-z0-9', ' ').split(" ").join('-')
    end

    private

    # Performs HTTP basic auth that works with Authlogic
    def require_http_auth_user

      render :json => { :errors => 'unauthorized', status: 401 } unless Setting.api_open?

      authenticate_or_request_with_http_basic do |username, password|
        user = User.where(:email => username).first
        if user.valid_password?(password)         # this is an Authlogic method
          @current_user = user
          true   # nothing pays attention to true/false anymore from filters
        else
          @current_user = nil
          render :json => { :errors => 'unauthorized', status: 401 }
        end
      end
    end

  end
end
