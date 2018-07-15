require 'rails_helper'

RSpec.describe PresentationSpeakersController, type: :controller do
  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  describe "POST #create" do
    before do
      post :create, params: { presentation_speaker: { presentation_id: 1, speaker_id: 1 }}
    end

    it "sets the creator" do
      expect(assigns(:presentation_speaker).creator_id).to eq(@current_user.id)
    end

    it "saves the presentation speaker" do
      expect(assigns(:presentation_speaker).errors).to be_empty
      expect(assigns(:presentation_speaker).id).to be_present
    end

    it "redirects to the manage_speakers page for the presentation" do
      expect(response).to redirect_to manage_speakers_presentation_path(1)
    end
  end

  describe "DELETE #destroy" do
    before do
      @presentation_speaker = create :presentation_speaker
      delete :destroy, params: {id: @presentation_speaker.to_param}
    end

    it "finds the presentation/speaker relationship" do
      expect(assigns(:presentation_speaker)).to eq(@presentation_speaker)
    end

    it "destroys the presentation/speaker relationship" do
      expect { @presentation_speaker.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

end
