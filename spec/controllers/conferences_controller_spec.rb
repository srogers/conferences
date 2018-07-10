require 'rails_helper'

RSpec.describe ConferencesController, type: :controller do
  fixtures :roles
  fixtures :settings

  # This should return the minimal set of attributes required to create a valid
  # Conference. As you add validations to Conference, be sure to
  # adjust the attributes here as well.
  let(:organizer) { create :organizer }

  let(:valid_attributes) {
    {
      organizer_id: organizer.id,
      start_date:   '2005/07/15'.to_date,
      end_date:     '2005/07/23'.to_date
    }
  }

  let(:invalid_attributes) {
    { start_date:   nil }
  }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.admin
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ConferencesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "when listing conferences" do
    before do
      @conference = Conference.create! valid_attributes
    end

    it "assigns all conferences as @conferences" do
      get :index, params: {}
      expect(assigns(:conferences)).to eq([@conference])
    end

    context "with a search term" do
      it "finds conferences with organizer name matching" do
        get :index, params:{ search_term: 'Organ' }
        expect(assigns(:conferences)).to eq([@conference])
      end

      it "finds conferences with organizer series matching" do
        get :index, params:{ search_term: 'confe' }
        expect(assigns(:conferences)).to eq([@conference])
      end

      it "finds conferences with organizer abbbreviation matching" do
        get :index, params:{ search_term: 'OC' }
        expect(assigns(:conferences)).to eq([@conference])
      end

      it "it doesn't find non-matching conferences" do
        get :index, params:{ search_term: 'Wombats' }
        expect(assigns(:conferences)).to be_empty
      end
    end

    context "with an auto-complete search term" do
      it "finds conferences with years matching the search term" do
        get :index, params:{ q: '2005' }
        expect(assigns(:conferences)).to eq([@conference])
      end

      it "it doesn't find non-matching conferences" do
        get :index, params:{ q: '2003' }
        expect(assigns(:conferences)).to be_empty
      end
    end
  end

  describe "GET #show" do
    it "assigns the requested conference as @conference" do
      conference = Conference.create! valid_attributes
      get :show, params: {id: conference.to_param}
      expect(assigns(:conference)).to eq(conference)
    end
  end

  describe "GET #new" do
    it "assigns a new conference as @conference" do
      get :new, params: {}
      expect(assigns(:conference)).to be_a_new(Conference)
    end
  end

  describe "GET #edit" do
    it "assigns the requested conference as @conference" do
      conference = Conference.create! valid_attributes
      get :edit, params: {id: conference.to_param}
      expect(assigns(:conference)).to eq(conference)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Conference" do
        expect {
          post :create, params: {conference: valid_attributes}
        }.to change(Conference, :count).by(1)
      end

      it "assigns a newly created conference as @conference" do
        post :create, params: {conference: valid_attributes}
        expect(assigns(:conference)).to be_a(Conference)
        expect(assigns(:conference)).to be_persisted
      end

      it "redirects to the created conference" do
        post :create, params: {conference: valid_attributes}
        expect(response).to redirect_to(Conference.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved conference as @conference" do
        post :create, params: {conference: invalid_attributes}
        expect(assigns(:conference)).to be_a_new(Conference)
      end

      it "re-renders the 'new' template" do
        post :create, params: {conference: invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { start_date:   '2005/07/18'.to_date, end_date: '2005/07/25'.to_date }
      }

      it "updates the requested conference" do
        conference = Conference.create! valid_attributes
        expect(conference.start_date).to eq(valid_attributes[:start_date])
        put :update, params: {id: conference.to_param, conference: new_attributes}
        expect(assigns(:conference).start_date).to eq(new_attributes[:start_date])
      end

      it "redirects to the conference" do
        conference = Conference.create! valid_attributes
        put :update, params: {id: conference.to_param, conference: valid_attributes}
        expect(response).to redirect_to(conference)
      end
    end

    context "with invalid params" do
      it "assigns the conference as @conference" do
        conference = Conference.create! valid_attributes
        put :update, params: {id: conference.to_param, conference: invalid_attributes}
        expect(assigns(:conference)).to eq(conference)
      end

      it "re-renders the 'edit' template" do
        conference = Conference.create! valid_attributes
        put :update, params: {id: conference.to_param, conference: invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested conference" do
      conference = Conference.create! valid_attributes
      expect {
        delete :destroy, params: {id: conference.to_param}
      }.to change(Conference, :count).by(-1)
    end

    it "redirects to the conferences list" do
      conference = Conference.create! valid_attributes
      delete :destroy, params: {id: conference.to_param}
      expect(response).to redirect_to(conferences_url)
    end
  end
end
