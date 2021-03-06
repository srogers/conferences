class SupplementsController < ApplicationController

  include StickyNavigation

  before_action :get_event,      except: [:index, :download]
  before_action :get_supplement, except: [:index, :new, :create]
  before_action :check_nav_params, only: [:index]

  before_action :require_user,     only: [:index]

  # This drives the supplement dashboard, outside the context of specific events
  def index
    @supplements = Supplement.includes(:conference).order(params_to_sql('>conferences.start_date'))

    @supplements = @supplements.page(param_context(:page)).per(param_context(:per))
    repaginate_if_needed(@supplements)
  end

  def show
  end

  def edit
  end

  def new
    @supplement = Supplement.new
  end

  def create
    @supplement = Supplement.new supplement_params
    @supplement.description.strip!
    @supplement.creator_id = current_user.id
    @supplement.conference = @event
    if @supplement.save
      redirect_to event_path(@event)
    else
      flash.now[:error] = "Your supplement could not be saved: #{ @supplement.errors.full_messages.join(", ") }"
      logger.error "Supplement save failed: #{ @supplement.errors.full_messages.join(", ") }"
      render 'new'
    end
  end

  def update
    if @supplement.update_attributes supplement_params
      redirect_to event_path(@event)
    else
      flash.now[:error] = "Your changes could not be saved: #{ @supplement.errors.full_messages.join(', ') }"
      logger.error "Supplement update failed: #{ @supplement.errors.full_messages.join(', ') }"
      render 'edit'
    end
  end

  def download
    send_data @supplement.attachment.read, type: @supplement.content_type, disposition: 'inline', filename: @supplement.name
  end

  def destroy
    event = @supplement.conference
    if can?(:destroy, @supplement)
      @supplement.destroy
    else
      flash[:notice] = "You don't have rights to delete that supplemental info."
    end

    redirect_to event_path(@event)
  end

  private

  def get_supplement
    @supplement = Supplement.find params[:id]
  end

  def get_event
    if @supplement.present?
      @event = @supplement.conference
    else
      @event = Conference.friendly.find params[:event_id]
    end
  end

  def supplement_params
    params.require(:supplement).permit(:name, :description, :url, :attachment, :conference_id, :editors_notes)
  end
end
