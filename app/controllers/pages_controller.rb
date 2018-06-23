class PagesController < ApplicationController
  def index
  end

  def robots
    render layout: false, formats: [:text]
  end
end
