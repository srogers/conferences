class SettingsController < ApplicationController

  before_action :require_admin

  load_and_authorize_resource

  def index
    # Get all the settings directly in the view from the class methods, as it would be used in the code
    @setting = Setting.first  # the edit button uses this
  end

  def edit
  end

  # TODO - for some settings, updates may have logical consequences that require handling
  #        e.g., changing require_account_approval to false might mean that pending accounts should be forced to
  #        approved status, since that attribute can't be edited when approval is not required.
  def update
    if @setting.update setting_params
      @setting.update(require_account_approval: true) if setting_params[:closed_beta] == 'true'
      redirect_to settings_path, notice: 'Settings were successfully updated.'
    else
      render "edit"
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:require_account_approval, :closed_beta, :speaker_chart_floor, :api_open, :facebook_sharing, :base_event_year)
  end
end
