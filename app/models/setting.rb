class Setting < ApplicationRecord

  def self.require_account_approval?
    get_settings
    return @setting.require_account_approval
  end

  private

  def self.get_settings
    @setting = Setting.first
  end
end
