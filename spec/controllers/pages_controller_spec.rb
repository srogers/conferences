require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  fixtures :roles
  setup :activate_authlogic

  let(:user) { create :user }

  describe "GET #privacy_policy" do

    let!(:passage) { create :passage, Passage::PRIVACY_POLICY.merge(creator: user) }

    it "finds the passage by controller/action and assigns it as @passage" do
      get :privacy_policy
      expect(assigns(:privacy_policy).name).to eq('Privacy Policy')
    end

    context "with authenticated user" do
      before do
        @current_user = user
        log_in @current_user
      end

      it "finds the passage by controller/action and assigns it as @passage" do
        get :privacy_policy
        expect(assigns(:privacy_policy).name).to eq('Privacy Policy')
      end
    end
  end

  describe "GET #terms_of_service" do

    let!(:passage) { create :passage, Passage::TERMS_OF_SERVICE.merge(creator: user) }

    it "finds the passage by controller/action and assigns it as @passage" do
      get :terms_of_service
      expect(assigns(:terms_of_service).name).to eq('Terms of Service')
    end

    context "with authenticated user" do
      before do
        @current_user = user
        log_in @current_user
      end

      it "finds the passage by controller/action and assigns it as @passage" do
        get :terms_of_service
        expect(assigns(:terms_of_service).name).to eq('Terms of Service')
      end
    end
  end
end
