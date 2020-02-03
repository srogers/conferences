require 'rails_helper'

RSpec.describe PassagesController, type: :controller do
  fixtures :roles
  setup :activate_authlogic

  let(:admin_user) { create :admin_user }

  # This should return the minimal set of attributes required to create a valid
  # Passage. As you add validations to Passage, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: 'home', view: 'controller/name', assign_var: 'home', content: 'Welcome', creator: admin_user }
  }

  let(:invalid_attributes) {
    { name: 'home', content: '' }
  }

  before do
    @current_user = admin_user
    log_in @current_user
  end


  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PassagesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do

    let!(:passage) { create :passage }

    it "assigns all passages as @passages" do
      get :index, params: {}
      expect(assigns(:passages)).to eq([passage])
    end
  end

  describe "GET #show" do

    let!(:passage) { create :passage }

    it "assigns the requested passage as @passage" do
      get :show, params: {id: passage.to_param}
      expect(assigns(:passage)).to eq(passage)
    end
  end

  describe "GET #new" do
    it "assigns a new passage as @passage" do
      get :new, params: {}
      expect(assigns(:passage)).to be_a_new(Passage)
    end
  end

  describe "GET #edit" do

    let!(:passage) { create :passage }

    it "assigns the requested passage as @passage" do
      get :edit, params: {id: passage.to_param}
      expect(assigns(:passage)).to eq(passage)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Passage" do
        expect {
          post :create, params: {passage: valid_attributes}
        }.to change(Passage, :count).by(1)
      end

      it "assigns a newly created passage as @passage" do
        post :create, params: {passage: valid_attributes}
        # This provides some clue about what's happening if the valid_attributes are not actually valid
        puts "passage errors: #{ assigns(:passage).errors.full_messages }" if assigns(:passage).errors.present?
        expect(assigns(:passage)).to be_a(Passage)
        expect(assigns(:passage)).to be_persisted
      end

      it "redirects to the created passage" do
        post :create, params: {passage: valid_attributes}
        expect(response).to redirect_to(Passage.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved passage as @passage" do
        post :create, params: {passage: invalid_attributes}
        expect(assigns(:passage)).to be_a_new(Passage)
      end

      it "re-renders the 'new' template" do
        post :create, params: {passage: invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do

    let(:passage) { create :passage, content: 'Welcome'}

    context "with valid params" do
      let(:new_attributes) {
        { name: 'home', content: 'Welcome2' }
      }

      it "updates the requested passage" do
        expect(passage.content).to eq('Welcome')
        put :update, params: {id: passage.to_param, passage: new_attributes}
        expect(assigns(:passage).content).to eq('Welcome2')
      end

      it "redirects to the passage" do
        put :update, params: {id: passage.to_param, passage: valid_attributes}
        expect(response).to redirect_to(passage)
      end
    end

    context "with invalid params" do
      it "assigns the passage as @passage" do
        put :update, params: {id: passage.to_param, passage: invalid_attributes}
        expect(assigns(:passage)).to eq(passage)
      end

      it "re-renders the 'edit' template" do
        put :update, params: {id: passage.to_param, passage: invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do

    let!(:passage) { create :passage }

    it "destroys the requested passage" do
      expect {
        delete :destroy, params: {id: passage.to_param}
      }.to change(Passage, :count).by(-1)
    end

    it "redirects to the passages list" do
      delete :destroy, params: {id: passage.to_param}
      expect(response).to redirect_to(passages_url)
    end
  end

end
