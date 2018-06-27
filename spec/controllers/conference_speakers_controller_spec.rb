require 'rails_helper'

RSpec.describe ConferenceSpeakersController, type: :controller do
  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  describe "POST #create" do
    before do
      post :create, params: { conference_speaker: { conference_id: 1, speaker_id: 1 }}
    end

    it "sets the creator"
    it "saves the conference speaker"

    it "redirects to the conference show page" do
      expect(response).to redirect_to conference_path(1)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the conference speaker"
  end

end
