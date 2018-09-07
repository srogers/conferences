require 'rails_helper'

RSpec.describe PresentationPublicationsController, type: :controller do
  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  let(:presentation) { create :presentation }

  describe "POST #create" do
    before do
      post :create, params: { presentation_publication: { presentation_id: presentation.id, publication_id: 1 }}
    end

    it "sets the creator" do
      expect(assigns(:presentation_publication).creator_id).to eq(@current_user.id)
    end

    it "saves the presentation publication" do
      expect(assigns(:presentation_publication).errors).to be_empty
      expect(assigns(:presentation_publication).id).to be_present
    end

    it "redirects to the manage_publications page for the presentation" do
      expect(response).to redirect_to manage_publications_presentation_path(presentation)
    end
  end

  describe "DELETE #destroy" do
    before do
      @presentation_publication = create :presentation_publication, presentation_id: presentation.id
      delete :destroy, params: {id: @presentation_publication.to_param}
    end

    it "finds the presentation/publication relationship" do
      expect(assigns(:presentation_publication)).to eq(@presentation_publication)
    end

    it "destroys the presentation/publication relationship" do
      expect { @presentation_publication.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "redirects to the manage_publications page for the presentation" do
      expect(response).to redirect_to manage_publications_presentation_path(presentation)
    end
  end

end
