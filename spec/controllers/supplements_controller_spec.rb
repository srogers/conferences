require 'rails_helper'

RSpec.describe SupplementsController, type: :controller do

  fixtures :roles
  fixtures :settings

  let(:event)      { create :conference }
  let(:supplement) { create :supplement, conference: event }

  let(:valid_params) { HashWithIndifferentAccess.new(
    {supplement: {name: 'Bob', description: "Valid Supplement" , url: 'http://www.archive.org/some_program' }, event_id: event.to_param }
  ) }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.editor
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SupplementsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "when listing supplements" do
    it "assigns all supplements as @supplements" do
      get :index, params: {}
      expect(assigns(:supplements)).to eq([supplement])
    end
  end

  describe "GET #show" do
    it "assigns the requested supplement as @supplement" do
      get :show, params: { event_id: event.id, id: supplement.to_param }
      expect(assigns(:supplement)).to eq(supplement)
    end
  end

  describe "when downloading the attachment" do
    it "sends the attachment as a PDF download" do
      skip "set up an attachment"
      #get :download_handout, params: { id: supplement.to_param, event_id: event.to_param  }
    end
  end

  describe "GET #new" do
    it "assigns a new supplement as @supplement" do
      get :new, params: { event_id: event.to_param }
      expect(assigns(:supplement)).to be_a_new(Supplement)
    end
  end

  describe "GET #edit" do
    it "assigns the requested supplement as @supplement" do
      get :edit, params: {id: supplement.to_param, event_id: event.to_param }
      expect(assigns(:supplement)).to eq(supplement)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Supplement" do
        expect {
          post :create, params: valid_params
        }.to change(Supplement, :count).by(1)
      end

      it "assigns a newly created supplement as @supplement" do
        post :create, params: valid_params
        expect(assigns(:supplement)).to be_a(Supplement)
        expect(assigns(:supplement)).to be_persisted
      end

      it "redirects to the supplement's event" do
        post :create, params: valid_params
        expect(response).to redirect_to event_path(event)
      end
    end

    context "with invalid supplement attributes" do

      let(:invalid_params) { valid_params.merge(:supplement => {:description => ''}) }

      it "assigns a newly created but unsaved supplement as @supplement" do
        post :create, params: invalid_params
        expect(assigns(:supplement)).to be_a_new(Supplement)
      end

      it "returns to the creation form" do
        post :create, params: invalid_params
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do

    let(:update_params) { valid_params.merge(id: supplement.to_param, supplement: {description: 'Updated Description' }) } # just like create, but with an added ID

    context "with valid params" do

      before { put :update, params: update_params }

      it "updates the requested supplement" do
        expect(assigns(:supplement).description).to eq(update_params[:supplement][:description])
      end

      it "redirects to the event" do
        expect(response).to redirect_to event_path(event)
      end
    end

    context "with invalid supplement params" do

      let(:invalid_supplement_params) { update_params.merge(:supplement => {:description => ''}) }

      before { put :update, params: invalid_supplement_params }

      it "assigns the supplement as @supplement" do
        expect(assigns(:supplement)).to eq(supplement)
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do

    before { expect(supplement).to be_present } # in these cases, touch it in advance to create it

    it "destroys the requested supplement" do
      expect {
        delete :destroy, params: {id: supplement.to_param, event_id: event.to_param }
      }.to change(Supplement, :count).by(-1)
    end

    it "redirects to the event" do
      delete :destroy, params: {id: supplement.to_param, event_id: event.to_param }
      expect(response).to redirect_to event_path(event)
    end
  end
end
