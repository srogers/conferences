require 'rails_helper'

RSpec.describe RelationsController, type: :controller do
  fixtures :roles
  fixtures :settings

  # This should return the minimal set of attributes required to create a valid
  # Relation. As you add validations to Relation, be sure to adjust the attributes here as well.
  let(:valid_attributes) {
    { name: "Valid Relation"}
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:relation) { Relation.create! valid_attributes }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.admin
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # RelationsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Relation" do
        expect {
          post :create, params: {relation: valid_attributes}
        }.to change(Relation, :count).by(1)
      end

      it "assigns a newly created relation as @relation" do
        post :create, params: {relation: valid_attributes}
        expect(assigns(:relation)).to be_a(Relation)
        expect(assigns(:relation)).to be_persisted
      end

      it "redirects to the created relation" do
        post :create, params: {relation: valid_attributes}
        expect(response).to redirect_to(Relation.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved relation as @relation" do
        post :create, params: {relation: invalid_attributes}
        expect(assigns(:relation)).to be_a_new(Relation)
      end

      it "re-renders the 'new' template" do
        post :create, params: {relation: invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end


  describe "DELETE #destroy" do
    before do
      expect(relation).to be_present # in these cases, touch it in advance to create it
    end

    it "destroys the requested relation" do
      expect {
        delete :destroy, params: {id: relation.to_param}
      }.to change(Relation, :count).by(-1)
    end

    context "with a publication using relation" do

      let!(:publication) { create :publication, relation_id: relation.id }

      it "does not destroy the requested relation" do
        expect {
          delete :destroy, params: {id: relation.to_param}
        }.not_to change(Relation, :count)

      end
    end

    it "redirects to the relations list" do
      delete :destroy, params: {id: relation.to_param}
      expect(response).to redirect_to(relations_url)
    end
  end
end
