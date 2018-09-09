module Api
  # Actions that get data open to the public respond with JSON on the normal routes.
  # The API handles only creates/updates requiring auth.

  class ApiController < ActionController::Base

    protect_from_forgery with: :null_session              # Prevents the API from being locked down by CSRF checks
    before_action       :require_http_auth_user           # Use HTTP Basic Auth instead of standard auth

    private

    # Performs HTTP basic auth that works with Authlogic
    def require_http_auth_user
      authenticate_or_request_with_http_basic do |username, password|
        user = User.where(:email => username).first
        if user.valid_password?(password)         # this is an Authlogic method
          true   # nothing pays attention to true/false anymore from filters
        else
          render :json => { :error => 'unauthorized', status: 401 }
        end
      end
    end

  end
end
