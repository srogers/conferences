require 'rails_helper'

describe SettingsController do
  fixtures :roles
  fixtures :settings
  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.admin
    log_in @current_user

    @setting = settings(:first)
  end

  describe "GET index (show settings)" do
    it "should find the one setting" do
      get 'index'
      expect(assigns[:setting]).to eq(@setting)
    end
  end

  describe "GET edit" do
    it "should be successful" do
      get 'edit', params: { :id => settings(:first).id.to_param }
      expect(response).to be_successful
    end
  end

  describe "PATCH update" do
    it "should update the settings" do
      current_value = settings(:first).require_account_approval
      patch 'update', params: { id: settings(:first).id.to_param, setting: { require_account_approval: !current_value } }

      expect(Setting.first.require_account_approval).not_to eq(current_value)
    end

    it "should redirect to the settings path" do
      patch 'update', params: { id: settings(:first).id.to_param, setting: { require_account_approval: true } }
      expect(response).to redirect_to(settings_path)
    end

    context "with invalid data" do
      it "should re-render edit"
    end
  end
end
