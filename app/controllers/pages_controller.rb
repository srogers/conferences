class PagesController < ApplicationController
  # Handles static pages that should be available to anyone. Don't put anything here that needs guarding, or a spec

  include PassageManagement

  def robots
    render layout: false, formats: [:text]
  end

  def privacy_policy
    get_passages
    @current_user.set_privacy_policy_current if @current_user.present?
  end

  def terms_of_service
    get_passages
    # Currently not tracking user views or redirecting users based on TOS updates
  end
end
