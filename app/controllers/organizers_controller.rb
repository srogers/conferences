class OrganizersController < ApplicationController

  before_action :get_organizer, except: [:create, :new, :index]

  load_and_authorize_resource

  def index
    @organizers = Organizer.order(:name).page(params[:page]).per(20)
  end

  def show
  end

  def edit
  end

  def new
  end

  def create
    @organizer = Organizer.new organizer_params
    @organizer.name&.strip!
    @organizer.series_name&.strip!
    @organizer.abbreviation&.strip!

    if @organizer.save
      redirect_to organizer_path(@organizer)
    else
      flash[:error] = "Your organizer could not be saved: #{ @organizer.errors.full_messages.join(", ") }"
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
    @organizer.destroy

    redirect_to organizers_path
  end

  private

  def get_organizer
    @organizer = Organizer.find params[:id]
  end

  def organizer_params
    params.require(:organizer).permit(:name, :series_name, :abbreviation)
  end
end
