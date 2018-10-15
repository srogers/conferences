class UserPresentationsController < ApplicationController

  before_action :require_user

  def index
    @user_presentations = current_user.user_presentations.includes(:presentation)
  end

  def create
    @user_presentation = UserPresentation.new user_presentation_params
    if @user_presentation.save
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

  def destroy
    @user_presentation = UserPresentation.find(params[:id])
    if @user_presentation
      presentation_id = @user_presentation.presentation.to_param
      @user_presentation.destroy
      redirect_to presentation_path(presentation_id)
    else
      render body: nil
    end
  end

  def user_presentation_params
    params.require(:user_presentation).permit(:presentation_id, :user_id)
  end
end
