class Setting < ApplicationRecord

  def self.require_account_approval?
    get_settings
    return @setting.require_account_approval
  end

  def self.speaker_chart_floor
    get_settings
    return @setting.speaker_chart_floor || 3
  end

  def self.api_open?
    get_settings
    return @setting.api_open
  end

  def self.facebook_sharing?
    get_settings
    return @setting.facebook_sharing
  end

  def self.base_event_year
    get_settings
    return @setting.base_event_year || 1959
  end

  private

  def self.get_settings
    @setting = Setting.first
  end
end
