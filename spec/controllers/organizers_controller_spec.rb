require 'rails_helper'

RSpec.describe OrganizersController, type: :controller do
  fixtures :roles
  fixtures :settings

  # This should return the minimal set of attributes required to create a valid
  # Organizer. As you add validations to Organizer, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: "Valid Organizer" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

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
    before do
      @organizer = Organizer.create! valid_attributes
    end

    it "assigns all organizers as @organizers" do
      get :index, params: {}
      expect(assigns(:organizers)).to eq([@organizer])
    end
  end

  describe "GET #show" do
    it "assigns the requested organizer as @organizer" do
      organizer = Organizer.create! valid_attributes
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
      organizer = Organizer.create! valid_attributes
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

      it "updates the requested organizer" do
        organizer = Organizer.create! valid_attributes
        expect(organizer.name).to eq('Valid Organizer')
        put :update, params: {id: organizer.to_param, organizer: new_attributes}
        expect(assigns(:organizer).name).to eq(new_attributes[:name])
      end

      it "redirects to the organizer" do
        organizer = Organizer.create! valid_attributes
        put :update, params: {id: organizer.to_param, organizer: valid_attributes}
        expect(response).to redirect_to(organizer)
      end
    end

    context "with invalid params" do
      it "assigns the organizer as @organizer" do
        organizer = Organizer.create! valid_attributes
        put :update, params: {id: organizer.to_param, organizer: invalid_attributes}
        expect(assigns(:organizer)).to eq(organizer)
      end

      it "re-renders the 'edit' template" do
        organizer = Organizer.create! valid_attributes
        put :update, params: {id: organizer.to_param, organizer: invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested organizer" do
      organizer = Organizer.create! valid_attributes
      expect {
        delete :destroy, params: {id: organizer.to_param}
      }.to change(Organizer, :count).by(-1)
    end

    it "redirects to the organizers list" do
      organizer = Organizer.create! valid_attributes
      delete :destroy, params: {id: organizer.to_param}
      expect(response).to redirect_to(organizers_url)
    end
  end
end
