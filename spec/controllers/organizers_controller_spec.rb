require 'rails_helper'

RSpec.describe OrganizersController, type: :controller do
  fixtures :roles
  fixtures :settings

  # This should return the minimal set of attributes required to create a valid
  # Organizer. As you add validations to Organizer, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: "Valid Organizer", series_name: "Conference Series", abbreviation: "ConSer"}
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:organizer) { Organizer.create! valid_attributes }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.admin
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # OrganizersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "when listing organizers" do
    it "assigns all organizers as @organizers" do
      get :index, params: {}
      expect(assigns(:organizers)).to eq([organizer])
    end
  end

  describe "GET #show" do
    it "assigns the requested organizer as @organizer" do
      get :show, params: {id: organizer.to_param}
      expect(assigns(:organizer)).to eq(organizer)
    end
  end

  describe "GET #new" do
    it "assigns a new organizer as @organizer" do
      get :new, params: {}
      expect(assigns(:organizer)).to be_a_new(Organizer)
    end
  end

  describe "GET #edit" do
    it "assigns the requested organizer as @organizer" do
      get :edit, params: {id: organizer.to_param}
      expect(assigns(:organizer)).to eq(organizer)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Organizer" do
        expect {
          post :create, params: {organizer: valid_attributes}
        }.to change(Organizer, :count).by(1)
      end

      it "assigns a newly created organizer as @organizer" do
        post :create, params: {organizer: valid_attributes}
        expect(assigns(:organizer)).to be_a(Organizer)
        expect(assigns(:organizer)).to be_persisted
      end

      it "redirects to the created organizer" do
        post :create, params: {organizer: valid_attributes}
        expect(response).to redirect_to(Organizer.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved organizer as @organizer" do
        post :create, params: {organizer: invalid_attributes}
        expect(assigns(:organizer)).to be_a_new(Organizer)
      end

      it "re-renders the 'new' template" do
        post :create, params: {organizer: invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { name: 'Updated Title' }
      }

      before do
        put :update, params: {id: organizer.to_param, organizer: new_attributes}
      end

      it "updates the requested organizer" do
        expect(organizer.name).to eq('Valid Organizer')
        expect(assigns(:organizer).name).to eq(new_attributes[:name])
      end

      it "redirects to the organizer" do
        expect(response).to redirect_to(organizer)
      end
    end

    context "with invalid params" do
      before do
        put :update, params: {id: organizer.to_param, organizer: invalid_attributes}
      end

      it "assigns the organizer as @organizer" do
        put :update, params: {id: organizer.to_param, organizer: invalid_attributes}
        expect(assigns(:organizer)).to eq(organizer)
      end

      it "re-renders the 'edit' template" do
        put :update, params: {id: organizer.to_param, organizer: invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      expect(organizer).to be_present # in these cases, touch it in advance to create it
    end

    it "destroys the requested organizer" do
      expect {
        delete :destroy, params: {id: organizer.to_param}
      }.to change(Organizer, :count).by(-1)
    end

    context "with an organizer owning events" do

      let!(:conference) { create :conference, organizer_id: organizer.id }

      it "does not destroy the requested conference" do
        expect {
          delete :destroy, params: {id: organizer.to_param}
        }.not_to change(Organizer, :count)

      end
    end

    it "redirects to the organizers list" do
      delete :destroy, params: {id: organizer.to_param}
      expect(response).to redirect_to(organizers_url)
    end
  end
end
