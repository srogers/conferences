class RelationsController < ApplicationController

  load_resource only: [:destroy]
  authorize_resource

  def new
    @relation = Relation.new
  end

  def create
    @relation = Relation.new language_params
    @relation.name&.strip!

    if @relation.save
      redirect_to language_path(@relation)
    else
      flash.now[:error] = "Your language could not be saved: #{ @relation.errors.full_messages.join(", ") }"
      logger.error "Relation save failed: #{ @relation.errors.full_messages.join(", ") }"
      render 'new'
    end
  end

  def destroy
    if can?(:destroy, @relation) && @relation.publications.empty?
      @relation.destroy
    else
      flash[:notice] = "Relation can't be deleted because publication(s) are using it."
    end

    redirect_to manage_related_presentation_path(@presentation)
  end

end
