class Setting < ApplicationRecord

  def self.require_account_approval?
    get_settings
    return @setting.require_account_approval
  end

  def self.speaker_chart_floor
    get_settings
    return @setting.speaker_chart_floor || 3
  end

  private

  def self.get_settings
    @setting = Setting.first
  end
end
