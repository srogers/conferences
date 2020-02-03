class PagesController < ApplicationController
  # Handles static pages that should be available to anyone. Don't put anything here that needs guarding, or a spec

  include PassageManagement

  def robots
    render layout: false, formats: [:text]
  end

  def privacy_policy
    get_passages
  end
end
