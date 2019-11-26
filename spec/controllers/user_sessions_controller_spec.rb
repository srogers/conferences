require 'rails_helper'

describe UserSessionsController do
  fixtures :roles, :settings
  setup :activate_authlogic

  let(:valid_params)  { { user_session: { email: ' spacey@example.com ', password: ' typo-city '} } }

  describe "when getting login form" do
    it "requires user is not currently logged in" do
      @current_user = create :user, role: Role.reader
      log_in @current_user
      get :new
      expect(response).to redirect_to root_path
    end
  end

  describe "when logging in" do
    before do
      # Raven introduces the need for persisting? and priority_record= because of ApplicationController#set_raven_context
      @mock_valid_session   = double(UserSession, save: true, persisting?: true,   'priority_record=' => true,  user: @current_user)
      @mock_invalid_session = double(UserSession, save: false, persisting?: false, 'priority_record=' => false, user: nil, errors: double(StandardError, full_messages: ['it failed']))
    end

    it "strips off leading spaces from user name and password" do
      expect(UserSession).to receive(:new).with({'priority_record': nil}, nil).and_return @mock_valid_session # Raven causes this
      expect(UserSession).to receive(:new).with('email' => 'spacey@example.com', 'password' => 'typo-city').and_return @mock_valid_session
      post :create, params: { user_session: { email: ' spacey@example.com ', password: ' typo-city '} }
    end

    context "when session is successfully created" do
      before do
        allow(UserSession).to receive(:new).and_return @mock_valid_session
      end

      it "redirects to root path" do
        post :create, params: valid_params
        expect(response).to redirect_to root_path
      end
    end

    context "when session is not created" do
      before do
        allow(UserSession).to receive(:new).and_return @mock_invalid_session
      end

      it "renders the login form" do
        post :create, params: valid_params
        expect(response).to render_template 'new'
        expect(response).not_to be_redirect
      end
    end
  end

  describe "when logging in" do
    before do
      @current_user = create :user, role: Role.reader, email: 'spacey@example.com', password: 'r3trorockets', password_confirmation: 'r3trorockets'
    end

    it "creates a user session" do
      post :create, params: { user_session: { email: 'spacey@example.com', password: 'r3trorockets'} }
      expect(UserSession.find).not_to be_nil
    end
  end

  describe "when logging out" do
    before do
      @current_user = create :user, role: Role.reader
      log_in @current_user
    end

    it "redirects to the root path" do
      delete :destroy
      expect(response).to redirect_to root_path
    end

    it "destroys the user session" do
      expect(UserSession.find).not_to be_nil
      delete :destroy
      expect(UserSession.find).to be_nil
    end
  end
end
