require 'rails_helper'

describe SettingsController do
  fixtures :roles
  fixtures :settings
  setup :activate_authlogic

  let(:setting) { Setting.first }    # This should always exist, so don't use a factory for it

  before do
    @current_user = create :user, role: Role.admin
    log_in @current_user
  end

  describe "GET index (show settings)" do
    it "should find the one setting" do
      get 'index'
      expect(assigns[:setting]).to eq(setting)
    end
  end

  describe "When editing setting" do
    it "finds the one unique setting record" do
      get 'edit', params: { :id => setting.id.to_param }
    end

    it "is successful" do
      expect(response).to be_successful
    end
  end

  describe "When updating" do
    describe "require account approval" do
      it "updates the setting" do
        current_value = setting.require_account_approval
        patch 'update', params: { id: setting.id.to_param, setting: { require_account_approval: (!current_value).to_s } }

        expect(Setting.first.require_account_approval).not_to eq(current_value)
      end
    end

    describe "closed beta" do
      it "updates the setting" do
        current_value = setting.closed_beta
        patch 'update', params: { id: setting.id.to_param, setting: { closed_beta: (!current_value).to_s } }

        expect(Setting.first.closed_beta).not_to eq(current_value)
      end

      it "ensures account approval is also required" do
        expect(Setting.first.require_account_approval).to be_falsey
        patch 'update', params: { id: setting.id.to_param, setting: { closed_beta: 'true' } }

        expect(Setting.first.require_account_approval).to be_truthy
      end
    end

    it "redirects to the settings path" do
      patch 'update', params: { id: setting.id.to_param, setting: { require_account_approval: 'true' } }
      expect(response).to redirect_to(settings_path)
    end

    context "with invalid data" do
      it "should re-render edit"
    end
  end
end
