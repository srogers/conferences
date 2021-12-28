class RelationsController < ApplicationController

  load_resource only: [:destroy]
  authorize_resource

  def create
    @relation = Relation.new relation_params
    @relation.notes&.strip!

    if @relation.save
      redirect_to manage_related_presentation_path(@relation.presentation)
    else
      flash[:error] = "Relationship could not be saved: #{ @relation.errors.full_messages.join(", ") }"
      logger.error "Relation save failed: #{ @relation.errors.full_messages.join(", ") }"
      destination = if params[:relation] && params[:relation][:presentation_id]
        manage_related_presentation_path(params[:relation][:presentation_id])
      else
        root_path
      end
      redirect_to destination
    end
  end

  def destroy
    if can?(:destroy, @relation)
      destination = @relation.presentation
      @relation.destroy
    else
      flash[:notice] = "Relation can't be deleted"
    end

    redirect_to manage_related_presentation_path(destination)
  end

  def relation_params
    params.require(:relation).permit(
      :presentation_id, :related_id, :kind
    )
  end

end
