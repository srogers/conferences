require 'rails_helper'

RSpec.describe DocumentsController, type: :controller do
  fixtures :roles
  setup :activate_authlogic

  let(:document) { create :document }

  context "with admin user" do
    before do
      @current_user = create :user, role: Role.admin
      log_in @current_user
    end

    describe "GET index" do
      let(:document2) { create :document }

      it "assigns all documents as @documents" do
        get :index
        expect(assigns(:documents)).to match_array([document, document2])
      end
    end

    describe "GET download" do
      it "sends the document PDF attachment" do
        skip "set up an attachment"
        #get :download, params: { id: document.id }
      end
    end

    describe "DELETE destroy" do
      it "sets up the user correctly" do
        expect(@current_user.admin?).to be_truthy
      end

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
