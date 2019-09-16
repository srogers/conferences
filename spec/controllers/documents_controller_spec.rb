require 'rails_helper'

RSpec.describe DocumentsController, type: :controller do
  fixtures :roles
  setup :activate_authlogic

  let!(:document)  { create :document }
  let!(:document2) { create :document }
  let!(:document_pending) { create :document }

  before do
    # Force the status of the two docs to COMPLETE
    document.complete!
    document2.complete!
  end

  context "with guest user" do
    before do
      log_out
      pretend_to_be_logged_out
    end

    describe "GET index" do
      it "should redirect" do
        get :index
        expect(response).to redirect_to login_path
      end
    end
  end

  context "with reader user" do
    before do
      current_user = create :user, role: Role.reader
      log_in current_user
    end

    describe "GET index" do
      it "assigns all documents as @documents" do
        get :index
        expect(assigns(:documents)).to match_array([document, document2])
      end
    end
  end

  context "with editor user" do
    before do
      current_user = create :user, role: Role.editor
      log_in current_user
    end

    describe "GET index" do
      it "assigns all documents as @documents" do
        get :index
        expect(assigns(:documents)).to match_array([document, document2])
      end
    end
  end

  context "with admin user" do
    before do
      current_user = create :user, role: Role.admin
      log_in current_user
    end

    describe "GET index" do

      it "assigns all documents as @documents" do
        get :index
        expect(assigns(:documents)).to match_array([document, document2, document_pending])
      end
    end

    describe "GET download" do
      let(:uploader) { DocumentUploader.new(document, :attachment) }

      before do
        DocumentUploader.enable_processing = true
        File.open('spec/fixtures/files/blank.pdf') { |f| uploader.store!(f) }
        get :download, params: { id: document.id }
      end

      after do
        DocumentUploader.enable_processing = false
        uploader.remove!
      end

      it "sends the document PDF attachment" do
        expect(response).to be_successful
        expect(response.headers["Content-Type"]).to eq "attachment/pdf"
      end

      it "came from the correct attachment" do
        expect(uploader.send(:original_filename)).to eq('blank.pdf')
      end

      it "has the correct format" do
        expect(uploader.model.format).to eq('PDF')
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested document" do
        this_document = create :document
        expect { delete :destroy, params: { :id => this_document.to_param } }.to change(Document, :count).by(-1)
      end

      it "redirects to the listing" do
        delete :destroy, params: { :id => document.to_param }
        expect(response).to redirect_to(documents_path)
      end
    end
  end
end
