class UserPresentationsController < ApplicationController

  before_action :require_user  # guests shouldn't ever see any buttons that go here

  def index
    @user_presentations = current_user.user_presentations.includes(:presentation => :conference).order('conferences.start_date DESC', 'presentations.name')
  end

  def create
    @user_presentation = UserPresentation.new user_presentation_params.merge(user_id: current_user.id)
    @success = @user_presentation.save
    get_user_presentation_list
    respond_to do |format|
      format.html do
        if @success
          redirect_to presentation_path(@user_presentation.presentation.to_param)
        else
          flash[:error] = 'The presentation could not be added to your list.'
          logger.error "UserPresentation save failed: #{ @user_presentation.errors.full_messages }"
          if @user_presentation&.presentation_id
            redirect_to presentation_path(@user_presentation.presentation.to_param)
          else
            redirect_to presentations_path
          end
        end
      end
      # This renders /create.js.erb, which renders the _presentation partial for a specific entry in the presentations
      # listing, or the listing on conference show page.
      format.js
    end
  end

  def update
    get_user_presentation
    @user_presentation.update user_presentation_params
    get_user_presentation_list

    respond_to do |format|
      format.html do          # currently, only presentation/show uses this
        redirect_to presentation_path(@user_presentation.presentation.to_param)
      end
      format.js               # renders /update.js.erb which re-renders the presentation with the clicked object
    end
  end

  def destroy
    get_user_presentation
    if @user_presentation
      presentation_id = @user_presentation.presentation.to_param
      @user_presentation.destroy
      success = true
    else
      success = false
    end

    respond_to do |format|
      format.html do
        if @success
          redirect_to presentation_path(presentation_id)
        else
          render body: nil
        end
      end
      format.js
    end
  end

  private

  def get_user_presentation
    @user_presentation = UserPresentation.find(params[:id])
  end

  def get_user_presentation_list
    @user_presentations = current_user.user_presentations
  end

  # :user_id is always overridden on create with the current_user's ID, and it can't be updated, so it's not allowed.
  def user_presentation_params
    params.require(:user_presentation).permit(:presentation_id, :notify_pubs, :completed_on)
  end
end
