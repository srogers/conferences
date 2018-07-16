require 'rails_helper'

RSpec.describe PublicationsController, type: :controller do

  let(:valid_attributes) {
    { format: Publication::FORMATS.first, presentation_id: 1 }
  }

  let(:invalid_attributes) {
    { format: Publication::FORMATS.first, presentation_id: nil }
  }

  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  describe "POST #create" do
    before do
      post :create, params: { publication: valid_attributes }
    end

    it "sets the creator" do
      expect(assigns(:publication).creator_id).to eq(@current_user.id)
    end

    it "saves the publication" do
      expect(assigns(:publication).errors).to be_empty
      expect(assigns(:publication).id).to be_present
    end

    it "redirects to the manage_publications page for the presentation" do
      expect(response).to redirect_to manage_publications_presentation_path(assigns(:publication).presentation_id)
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { format: Publication::FORMATS.last }
      }

      it "updates the requested publication" do
        publication = Publication.create! valid_attributes
        expect(publication.format).to eq(valid_attributes[:format])
        put :update, params: {id: publication.to_param, publication: new_attributes}
        expect(assigns(:publication).format).to eq(new_attributes[:format])
      end

      it "redirects to the manage publication page for the presentation" do
        publication = Publication.create! valid_attributes
        put :update, params: {id: publication.to_param, publication: valid_attributes}
        expect(response).to redirect_to manage_publications_presentation_path(publication.presentation_id)
      end
    end

    context "with invalid params" do
      it "assigns the publication as @publication" do
        publication = Publication.create! valid_attributes
        put :update, params: {id: publication.to_param, publication: invalid_attributes}
        expect(assigns(:publication)).to eq(publication)
      end

      it "re-renders the 'edit' template" do
        publication = Publication.create! valid_attributes
        put :update, params: {id: publication.to_param, publication: invalid_attributes}
        expect(response).to render_template("edit")
      end
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
      expect(response).to redirect_to manage_publications_presentation_path(@publication.presentation_id)
    end
  end
end
