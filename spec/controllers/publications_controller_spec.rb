require 'rails_helper'

RSpec.describe PublicationsController, type: :controller do

  let(:presentation) { create :presentation }

  let(:valid_attributes) {
    { format: Publication::FORMATS.first, name: 'Valid Publication' }
  }

  let(:invalid_attributes) {
    { format: '', name: '' }
  }

  let(:publication) { Publication.create! valid_attributes }

  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  describe "when listing publications" do
    it "assigns all publications as @publications" do
      get :index, params: {}
      expect(assigns(:publications)).to eq([publication])
    end

    context "with a search term" do
      it "finds publications with matching names without regard to case" do
        get :index, params: { search_term: 'VALID' }
        expect(assigns(:publications)).to eq([publication])
      end

      it "doesn't find non-matching publications" do
        get :index, params: { search_term: 'Wombats' }
        expect(assigns(:publications)).to be_empty
      end
    end

    context "that need editor attention" do

      # set up data that meets all the criteria being checked:
      #   published_on present, duration present where applicable, and at least one presentation
      let!(:video_pub) { create :publication, format: Publication::YOUTUBE, published_on: Date.today, duration: 1 }
      let!(:print_pub) { create :publication, format: Publication::PRINT,   published_on: Date.today, duration: 1 }
      let!(:video_pres_pub) { create :presentation_publication, presentation_id: presentation.id, publication_id: video_pub.id }
      let!(:print_pres_pub) { create :presentation_publication, presentation_id: presentation.id, publication_id: print_pub.id }

      context "when all the basics are in place" do
        it "should not find any problems" do
          get :index, params: { heart: 'true' }
          expect(assigns(:publications)).not_to include(video_pub, print_pub) # it won't be blank due to basic publication
        end
      end

      context "to duration" do
        before do
          video_pub.update(duration: nil)
          print_pub.update(duration: nil)
          get :index, params: { heart: 'true' }
        end

        it "lists publications with blank duration" do
          expect(assigns(:publications)).to include(video_pub)
        end

        it "ignores publications where duration is not applicable" do
          expect(assigns(:publications)).not_to include(print_pub)
        end
      end
    end
  end

  describe "GET #new" do
    it "assigns a new publication as @publication" do
      get :new, params: {}
      expect(assigns(:publication)).to be_a_new(Publication)
    end
  end

  describe "GET #edit" do
    it "assigns the requested publication as @publication" do
      get :edit, params: { id: publication.to_param }
      expect(assigns(:publication)).to eq(publication)
    end

    it "assigns the requested presentation as @presentation when specified" do
      get :edit, params: { id: publication.to_param, presentation_id: presentation.id }
      expect(assigns(:presentation)).to eq(presentation)
    end
  end

  describe "POST #create" do

    let(:params) { { publication: valid_attributes } }

    before do
      post :create, params: params
    end

    it "sets the creator" do
      expect(assigns(:publication).creator_id).to eq(@current_user.id)
    end

    it "saves the publication" do
      expect(assigns(:publication).errors).to be_empty
      expect(assigns(:publication).id).to be_present
    end

    it "redirects to publication show page" do
      expect(response).to redirect_to publication_path(assigns(:publication))
    end

    context "when a presentation is specified" do

      let(:params) { { publication: valid_attributes, presentation_id: presentation.id  } }

      it "redirects to the manage_publications page for the presentation" do
        expect(response).to redirect_to manage_publications_presentation_path(presentation)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do

      let(:selected_format) { Publication::FORMATS.last }
      let(:params) { { id: publication.to_param, publication: { format: selected_format } } }

      before do
        put :update, params: params
      end

      it "updates the requested publication" do
        expect(assigns(:publication).format).to eq(selected_format)
      end

      it "redirects to the publication show page" do
        expect(response).to redirect_to publication_path(publication)
      end

      context "when a presentation is specified" do

        let(:params) { { id: publication.to_param, presentation_id: presentation.id, publication: { format: Publication::FORMATS.last } } }

        it "redirects to the manage publication page for the presentation" do
          expect(response).to redirect_to manage_publications_presentation_path(presentation)
        end
      end
    end

    context "with invalid params" do
      before do
        put :update, params: {id: publication.to_param, publication: invalid_attributes}
      end

      it "assigns the publication as @publication" do
        expect(assigns(:publication)).to eq(publication)
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do

    let(:params) { { id: publication.to_param } }

    before do
      delete :destroy, params: params
    end

    it "finds the publication" do
      expect(assigns(:publication)).to eq(publication)
    end

    it "destroys the publication" do
      expect { publication.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    context "with presentation ID specified" do

      let(:params) { { id: publication.to_param, presentation_id: presentation.id } }

      it "redirects to the manage_publications page for the presentation" do
        expect(response).to redirect_to manage_publications_presentation_path(presentation)
      end
    end
  end
end
