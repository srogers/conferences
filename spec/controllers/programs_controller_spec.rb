require 'rails_helper'

RSpec.describe ProgramsController, type: :controller do

  fixtures :roles
  fixtures :settings

  let(:event)   { create :conference }
  let(:program) { create :program }

  let(:valid_params) { HashWithIndifferentAccess.new(
    { program: { name: 'Bob', description: "Valid Program" , url: 'http://www.archive.org/some_program' }, event_id: event.to_param }
  ) }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.editor
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ProgramsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  # There is no index

  # There is no show

  describe "when downloading the attachment" do
    it "sends the attachment as a PDF download" do
      skip "set up an attachment"
      #get :download_handout, params: { id: program.to_param, event_id: event.to_param  }
    end
  end

  describe "GET #new" do
    it "assigns a new program as @program" do
      get :new, params: { event_id: event.to_param }
      expect(assigns(:program)).to be_a_new(Program)
    end
  end

  describe "GET #edit" do
    it "assigns the requested program as @program" do
      get :edit, params: { id: program.to_param, event_id: event.to_param }
      expect(assigns(:program)).to eq(program)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Program" do
        expect {
          post :create, params: valid_params
        }.to change(Program, :count).by(1)
      end

      it "assigns a newly created program as @program" do
        post :create, params: valid_params
        expect(assigns(:program)).to be_a(Program)
        expect(assigns(:program)).to be_persisted
      end

      it "redirects to the program's event" do
        post :create, params: valid_params
        expect(response).to redirect_to event_path(event)
      end
    end

    context "with invalid program attributes" do

      let(:invalid_params) { valid_params.merge(:program => {:description => ''}) }

      it "assigns a newly created but unsaved program as @program" do
        post :create, params: invalid_params
        expect(assigns(:program)).to be_a_new(Program)
      end

      it "returns to the creation form" do
        post :create, params: invalid_params
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do

    let(:update_params) { valid_params.merge(id: program.to_param, program: { description: 'Updated Description' }) } # just like create, but with an added ID

    context "with valid params" do

      before { put :update, params: update_params }

      it "updates the requested program" do
        puts "event_path  #{ event_path(event) }"
        expect(assigns(:program).description).to eq(update_params[:program][:description])
      end

      it "redirects to the event" do
        expect(response).to redirect_to event_path(event)
      end
    end

    context "with invalid program params" do

      let(:invalid_program_params) { update_params.merge(:program => {:description => ''}) }

      before { put :update, params: invalid_program_params }

      it "assigns the program as @program" do
        expect(assigns(:program)).to eq(program)
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do

    before { expect(program).to be_present } # in these cases, touch it in advance to create it

    it "destroys the requested program" do
      expect {
        delete :destroy, params: { id: program.to_param, event_id: event.to_param }
      }.to change(Program, :count).by(-1)
    end

    it "redirects to the event" do
      puts "event_path  #{ event_path(event) }"
      delete :destroy, params: { id: program.to_param, event_id: event.to_param }
      expect(response).to redirect_to event_path(event)
    end
  end
end
