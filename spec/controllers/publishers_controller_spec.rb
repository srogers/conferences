require 'rails_helper'

RSpec.describe PublishersController, type: :controller do
  fixtures :roles
  setup :activate_authlogic

  let(:admin_user) { create :admin_user }

  # This should return the minimal set of attributes required to create a valid
  # Publisher. As you add validations to Publisher, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: 'Third Renaissance' }
  }

  let(:invalid_attributes) {
    { name: '' }
  }

  before do
    @current_user = admin_user
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PublishersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do

    let!(:publisher) { create :publisher }

    it "assigns all publishers as @publishers" do
      get :index, params: {}
      expect(assigns(:publishers)).to eq([publisher])
    end
  end

  # no Show or New currently
  # describe "GET #show" do
  #
  #   let!(:publisher) { create :publisher }
  #
  #   it "assigns the requested publisher as @publisher" do
  #     get :show, params: {id: publisher.to_param}
  #     expect(assigns(:publisher)).to eq(publisher)
  #   end
  # end
  #
  # describe "GET #new" do
  #   it "assigns a new publisher as @publisher" do
  #     get :new, params: {}
  #     expect(assigns(:publisher)).to be_a_new(Publisher)
  #   end
  # end

  describe "GET #edit" do

    let!(:publisher) { create :publisher }

    it "assigns the requested publisher as @publisher" do
      get :edit, params: {id: publisher.to_param}
      expect(assigns(:publisher)).to eq(publisher)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Publisher" do
        expect {
          post :create, params: {publisher: valid_attributes}
        }.to change(Publisher, :count).by(1)
      end

      it "assigns a newly created publisher as @publisher" do
        post :create, params: {publisher: valid_attributes}
        # This provides some clue about what's happening if the valid_attributes are not actually valid
        puts "publisher errors: #{ assigns(:publisher).errors.full_messages }" if assigns(:publisher).errors.present?
        expect(assigns(:publisher)).to be_a(Publisher)
        expect(assigns(:publisher)).to be_persisted
      end

      it "redirects to the publisher list" do
        post :create, params: {publisher: valid_attributes}
        expect(response).to redirect_to publishers_path
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved publisher as @publisher" do
        post :create, params: {publisher: invalid_attributes}
        expect(assigns(:publisher)).to be_a_new(Publisher)
      end

      it "returns to the publishers listing" do
        post :create, params: {publisher: invalid_attributes}
        expect(response).to redirect_to publishers_path
      end
    end
  end

  describe "PUT #update" do

    let(:publisher) { create :publisher, name: 'First Renaissance'}

    context "with valid params" do
      let(:new_name)       { 'Fourth Renaissance' }
      let(:new_attributes) { { name: new_name } }

      it "updates the requested publisher" do
        put :update, params: {id: publisher.to_param, publisher: new_attributes}
        expect(assigns(:publisher).name).to eq(new_name)
      end

      it "redirects to the publisher" do
        put :update, params: {id: publisher.to_param, publisher: valid_attributes}
        expect(response).to redirect_to publishers_path
      end
    end

    context "with invalid params" do
      it "assigns the publisher as @publisher" do
        put :update, params: {id: publisher.to_param, publisher: invalid_attributes}
        expect(assigns(:publisher)).to eq(publisher)
      end

      it "returns to the publishers listing" do
        put :update, params: {id: publisher.to_param, publisher: invalid_attributes}
        expect(response).to render_template :edit
      end
    end
  end

  describe "DELETE #destroy" do

    let!(:publisher) { create :publisher }

    it "destroys the requested publisher" do
      expect {
        delete :destroy, params: {id: publisher.to_param}
      }.to change(Publisher, :count).by(-1)
    end

    it "redirects to the publishers list" do
      delete :destroy, params: {id: publisher.to_param}
      expect(response).to redirect_to(publishers_url)
    end
  end

end
