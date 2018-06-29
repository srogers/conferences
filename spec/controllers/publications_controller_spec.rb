require 'rails_helper'

RSpec.describe PublicationsController, type: :controller do
  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  describe "POST #create" do
    before do
      post :create, params: { publication: { presentation_id: 1, format: Publication::CD}}
    end

    it "sets the creator"
    it "saves the conference user"

    it "redirects to the conference show page" do
      expect(response).to redirect_to presentation_path(1)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the publication"
  end

end
