require 'rails_helper'

RSpec.describe EventUsersController, type: :controller do
  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  describe "POST #create" do
    before do
      post :create, params: { conference_user: { conference_id: 1, user_id: 1 }}
    end

    it "sets the creator" do
      expect(assigns(:conference_user).creator_id).to eq(@current_user.id)
    end

    it "saves the conference_user" do
      expect(assigns(:conference_user).errors).to be_empty
      expect(assigns(:conference_user).id).to be_present
    end

    it "redirects to the conference show page" do
      expect(response).to redirect_to event_path(1)
    end
  end

  describe "DELETE #destroy" do
    before do
      @conference_user = create :conference_user
      delete :destroy, params: {id: @conference_user.to_param}
    end

    it "finds the conference/user relationship" do
      expect(assigns(:conference_user)).to eq(@conference_user)
    end

    it "destroys the conference/user relationship" do
      expect { @conference_user.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "redirects to the conference show page" do
      expect(response).to redirect_to event_path(1)
    end
  end

  describe "when listing" do

    let(:user)             { create :user }
    let(:conference)       { create :conference }
    let!(:conference_user) { create :conference_user, user_id: user.id, conference_id: conference.id }

    context "without a conference_id" do
      it "redirects to events listing" do
        get :index, params: { user_id: user.id }

        expect(assigns(:conferences)).to be_nil
        expect(response).to redirect_to(events_path)
      end

      context "when user has disabled show_attendance preference" do
        before do
          user.update_attribute :show_attendance, false
        end

        it "does not list the conference for the user" do
          get :index, params: { conference_id: conference.id }

          expect(assigns(:conferences)).to be_nil
        end
      end
    end

    context "with a conference ID" do
      it "lists users for a conference" do
        get :index, params: { conference_id: conference.id }

        expect(assigns(:attendees)).to eq([user])
      end

      context "when user has disabled show_attendance preference" do
        before do
          user.update_attribute :show_attendance, false
        end

        it "does not list the user among attendees" do
          get :index, params: { conference_id: conference.id }

          expect(assigns(:attendees)).not_to include(user)
        end
      end
    end
  end
end
