require 'rails_helper'

RSpec.describe RelationsController, type: :controller do

  let(:source) { create :presentation }
  let(:target) { create :presentation }
  let(:kind)   { Relation::ABOUT }

  let(:valid_attributes) {
    { presentation_id: source.id, related_id: target.id, kind: kind }
  }

  let(:invalid_attributes) {
    { presentation_id: source.id, related_id: target.id, kind: "bogus" }
  }

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

      it "redirects to the manage relations page for the target presentation" do
        post :create, params: {relation: valid_attributes}
        expect(response).to  redirect_to manage_related_presentation_path(source)
      end
    end

    context "with invalid params" do
      it "redirects to the manage relations page for the target presentation" do
        post :create, params: {relation: invalid_attributes}
        expect(response).to  redirect_to manage_related_presentation_path(source.id) 
      end

      it "sets a flash message" do
        post :create, params: {relation: invalid_attributes}
        expect(flash[:error]).to match(/could not be saved/)
      end      
    end
  end


  describe "DELETE #destroy" do
    
    let!(:relation) { create :relation }            # has to be pre-created for .to change to work

    it "destroys the requested relation" do
      expect {
        delete :destroy, params: {id: relation.to_param}
      }.to change(Relation, :count).by(-1)
    end

    it "redirects to the manage relations list for the target presentation" do
      delete :destroy, params: {id: relation.to_param}
      expect(response).to redirect_to manage_related_presentation_path(relation.presentation)
    end
  end
end
