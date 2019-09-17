class OrganizersController < ApplicationController

  include Sortability

  load_resource except: [:create, :new, :index]
  authorize_resource

  def index
    @organizers = Organizer.includes(:conferences).order(params_to_sql('>organizers.abbreviation')).page(params[:page]).per(params[:per] || 10)
  end

  def show
  end

  def edit
  end

  def new
    @organizer = Organizer.new
  end

  def create
    @organizer = Organizer.new organizer_params
    @organizer.name&.strip!
    @organizer.series_name&.strip!
    @organizer.abbreviation&.strip!

    if @organizer.save
      redirect_to organizer_path(@organizer)
    else
      flash.now[:error] = "Your organizer could not be saved: #{ @organizer.errors.full_messages.join(", ") }"
      logger.debug "Organizer save failed: #{ @organizer.errors.full_messages.join(", ") }"
      render 'new'
    end
  end

  def update
    if @organizer.update_attributes organizer_params
      redirect_to organizer_path(@organizer)
    else
      flash.now[:error] = 'Your organizer could not be saved.'
      logger.debug "Organizer save failed: #{ @organizer.errors.full_messages }"
      render 'edit'
    end
  end

  def destroy
    if can?(:destroy, @organizer) && @organizer.conferences.empty?
      @organizer.destroy
    else
      flash[:notice] = "Organizer can't be deleted because it owns conferences."
    end

    redirect_to organizers_path
  end

  private

  def get_organizer
    @organizer = Organizer.find params[:id]
  end

  def organizer_params
    params.require(:organizer).permit(:name, :series_name, :abbreviation, :description)
  end
end
