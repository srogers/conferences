require 'rails_helper'

RSpec.describe UserPresentationsController, type: :controller do

  fixtures :roles
  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.reader, time_zone: "Central Time (US & Canada)"
    log_in @current_user
  end

  let(:presentation) { create :presentation }

  describe "GET #index" do

    let(:user_presentation) { create :user_presentation, user: @current_user }

    it "finds user presentations" do
      get :index
      expect(assigns(:user_presentations)).to eq([user_presentation])
    end
  end

  describe "POST #create" do
    before do
      # Specifically does not require :user_id
      post :create, params: { user_presentation: { presentation_id: presentation.id }}
    end

    it "saves the user presentation" do
      expect(assigns(:user_presentation).errors).to be_empty
      expect(assigns(:user_presentation).id).to be_present
    end

    it "redirects to the presentation page" do
      expect(response).to redirect_to presentation_path(presentation)
    end
  end

  describe "DELETE #destroy" do
    before do
      @user_presentation = create :user_presentation, presentation_id: presentation.id
      delete :destroy, params: {id: @user_presentation.to_param}
    end

    it "finds the presentation/user relationship" do
      expect(assigns(:user_presentation)).to eq(@user_presentation)
    end

    it "destroys the presentation/user relationship" do
      expect { @user_presentation.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "redirects to the presentation" do
      expect(response).to redirect_to presentation_path(presentation)
    end
  end
end
