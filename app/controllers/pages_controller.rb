class PagesController < ApplicationController

  # TODO - this is supposed to be the static pages controller, but the supporters page isn't entirely static.
  #        Is that a problem?
  def supporters
    @editors = User.editors
  end

  def robots
    render layout: false, formats: [:text]
  end
end
