require 'rails_helper'

RSpec.describe ConferenceUsersController, type: :controller do
  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  describe "POST #create" do
    before do
      post :create, params: { conference_user: { conference_id: 1, user_id: 1 }}
    end

    it "sets the creator"
    it "saves the conference user"

    it "redirects to the conference show page" do
      expect(response).to redirect_to conference_path(1)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the conference/user relationship"
  end

  describe "when listing" do

    let(:user)             { create :user }
    let(:conference)       { create :conference }
    let!(:conference_user) { create :conference_user, user_id: user.id, conference_id: conference.id }

    context "with a user ID" do
      it "lists conferences for a user" do
        get :index, params: { user_id: user.id }

        expect(assigns(:conferences)).to eq([conference])
      end

      context "when user has disabled show_attendance preference" do
        before do
          user.update_attribute :show_attendance, false
        end

        it "excludes user from attendees list" do
          get :index, params: { conference_id: conference.id }

          expect(assigns(:attendees).include?(user)).to be_falsey
        end
      end
    end

    context "with a conference ID" do
      it "lists users for a conference" do
        get :index, params: { conference_id: conference.id }

        expect(assigns(:attendees)).to eq([user])
      end
    end
  end
end
