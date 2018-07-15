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

    it "sets the creator" do
      expect(assigns(:publication).creator_id).to eq(@current_user.id)
    end

    it "saves the publication" do
      expect(assigns(:publication).errors).to be_empty
      expect(assigns(:publication).id).to be_present
    end

    it "redirects to the manage_publications page for the presentation" do
      expect(response).to redirect_to manage_publications_presentation_path(1)
    end
  end

  describe "DELETE #destroy" do
    before do
      @publication = create :publication
      delete :destroy, params: {id: @publication.to_param}
    end

    it "finds the publication" do
      expect(assigns(:publication)).to eq(@publication)
    end

    it "destroys the publication" do
      expect { @publication.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "redirects to the manage_publications page for the presentation" do
      expect(response).to redirect_to manage_publications_presentation_path(1)
    end
  end
end
