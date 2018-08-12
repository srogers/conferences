class SettingsController < ApplicationController

  before_action :require_admin
  load_and_authorize_resource

  def index
    @setting = Setting.first
  end

  def edit
  end

  # TODO - for some settings, updates may have logical consequences that require handling
  #        e.g., changing require_account_approval to false might mean that pending accounts should be forced to
  #        approved status, since that attribute can't be edited when approval is not required.
  def update
    if @setting.update setting_params
      redirect_to settings_path, notice: 'Settings were successfully updated.'
    else
      render "edit"
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:require_account_approval, :speaker_chart_floor)
  end

end
