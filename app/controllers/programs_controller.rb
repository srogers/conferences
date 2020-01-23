class ProgramsController < ApplicationController

  before_action :get_event,   except: [:download]
  before_action :get_program, except: [:new, :create]

  def edit
  end

  def new
    @program = Program.new
  end

  def create
    @program = Program.new program_params
    @program.description.strip!
    @program.creator_id = current_user.id
    @program.conference = @event
    if @program.save
      redirect_to event_path(@event)
    else
      flash.now[:error] = "Your program could not be saved: #{ @program.errors.full_messages.join(", ") }"
      logger.error "Program save failed: #{ @program.errors.full_messages.join(", ") }"
      render 'new'
    end
  end

  def update
    if @program.update_attributes program_params
      redirect_to event_path(@event)
    else
      flash.now[:error] = "Your changes could not be saved: #{ @program.errors.full_messages.join(', ') }"
      logger.error "Program update failed: #{ @program.errors.full_messages.join(', ') }"
      render 'edit'
    end
  end

  def download
    send_data @program.attachment.read, type: @program.content_type, disposition: 'inline', filename: @program.name
  end

  def destroy
    event = @program.conference
    if can?(:destroy, @program)
      @program.destroy
    else
      flash[:notice] = "You don't have rights to delete that program."
    end

    redirect_to event_path(@event)
  end

  private

  def get_program
    @program = Program.find params[:id]
  end

  def get_event
    if @program.present?
      @event = @program.conference
    else
      @event = Conference.friendly.find params[:event_id]
    end
  end

  def program_params
    params.require(:program).permit(:name, :description, :url, :attachment, :conference_id, :editors_notes)
  end
end
