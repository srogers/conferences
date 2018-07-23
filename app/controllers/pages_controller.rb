class PagesController < ApplicationController

  # Handles static pages that should be available to anyone. Don't put anything here that needs guarding, or a spec

  def robots
    render layout: false, formats: [:text]
  end
end
