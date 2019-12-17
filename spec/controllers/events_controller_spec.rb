require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  fixtures :roles
  fixtures :settings

  require_dependency Rails.root.join('lib', 'states') # shouldn't be necessary to load this explicitly, but it is

  # This should return the minimal set of attributes required to create a valid
  # Conference. As you add validations to Conference, be sure to
  # adjust the attributes here as well.
  let(:organizer) { create :organizer, name: 'Organization', abbreviation: 'WOMBAT' }

  let(:valid_attributes) {
    {
      name:         'Test Conference',
      event_type:   Conference::CONFERENCE,
      organizer_id: organizer.id,
      start_date:   '2005/07/15'.to_date,
      end_date:     '2005/07/23'.to_date
    }
  }

  let(:invalid_attributes) {
    { start_date:   nil }
  }

  let(:conference) { Conference.create! valid_attributes }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.editor
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # EventsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "when listing events" do
    it "assigns all events as @conferences" do
      get :index, params: {}
      expect(assigns(:conferences)).to eq([conference])
    end

    context "with a search term" do
      # Skip this - too expensive, and not that helpful - but keep the idea around for future reference
      #it "finds events with organizer abbreviation partial matching" do
      #  get :index, params:{ search_term: 'WOM' }
      #  expect(assigns(:conferences)).to eq([conference])
      #end

      it "finds events with conference name matching" do
        get :index, params:{ search_term: 'Test Conference' }
        expect(assigns(:conferences)).to eq([conference])
      end

      it "does not find events with organizer name matching" do
        get :index, params:{ search_term: 'Organization' }               # see organizer create above
        expect(assigns(:conferences)).to be_empty
      end

      it "it doesn't find non-matching events" do
        get :index, params:{ search_term: 'Zebras' }
        expect(assigns(:conferences)).to be_empty
      end

      context "for a user" do

        context "that is the current user" do

          let(:conference)            { create :conference, name: "My Conference" }
          let!(:this_conference_user) { create :conference_user, user_id: @current_user.id, conference_id: conference.id }

          it "lists the user's events" do
            get :index, params:{ user_id: @current_user.id }

            expect(assigns(:conferences)).to eq([conference])
          end
        end

        context "other than the current user" do

          let(:other_user)       { create :user }
          let(:other_conference) { create :conference, name: "Other Conference" }
          let!(:conference_user) { create :conference_user, user_id: other_user.id, conference_id: other_conference.id }

          context "with show_attendance preference disabled" do

            before { other_user.update show_attendance: false }

            it "lists all events" do
              get :index, params:{ user_id: other_user.id }

              expect(assigns(:conferences)).to match_array([conference, other_conference])
            end

            it "doesn't have a found user" do
              get :index, params:{ user_id: other_user.id }

              expect(assigns(:user)).to be_nil
            end

            context "as an admin viewer" do

              before { allow(@current_user).to receive(:admin?).and_return true }

              it "shows the user's events" do
                get :index, params: { user_id: other_user.id }

                expect(assigns(:conferences)).to eq([other_conference])
              end

            end
          end

          context "with show_attendance preference enabled" do

            before { other_user.update show_attendance: true }

            it "lists the user's events" do
              get :index, params:{ user_id: other_user.id }

              expect(assigns(:conferences)).to eq([other_conference])
            end
          end

        end
      end

    end

    context "with an auto-complete search term" do
      it "finds events with years matching the search term" do
        get :index, params:{ q: '2005' }
        expect(assigns(:conferences)).to eq([conference])
      end

      it "it doesn't find non-matching events" do
        get :index, params:{ q: '2003' }
        expect(assigns(:conferences)).to be_empty
      end
    end
  end

  describe "GET #show" do

    let(:user_presentation) { create :user_presentation, user_id: @current_user.id }

    it "assigns the requested conference as @conference" do
      get :show, params: {id: conference.to_param}
      expect(assigns(:conference)).to eq(conference)
    end

    it "assigns the current user's presentations" do
      get :show, params: {id: conference.to_param}
      expect(assigns(:user_presentations)).to eq([user_presentation])
    end

    # This is checked once for all the methods using get_conference
    context "with a moved conference" do
      before do
        conference.update(name: 'New Conference Name')
      end

      it "finds the conference with the old URL" do
        get :show, params: {id: 'test-conference'}
        expect(assigns(:conference)).to eq(conference)
        expect(response).to be_redirect
      end

      it "finds the conference with the new URL" do
        get :show, params: {id: 'new-conference-name'}
        expect(assigns(:conference)).to eq(conference)
      end
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
        expect(response).to redirect_to(event_path(Conference.last))
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

      before do
        put :update, params: {id: conference.to_param, conference: new_attributes}
      end

      it "updates the requested conference" do
        expect(assigns(:conference).start_date).to eq(new_attributes[:start_date])
      end

      it "redirects to the conference" do
        expect(response).to redirect_to(event_path(conference))
      end
    end

    context "with invalid params" do
      before do
        put :update, params: {id: conference.to_param, conference: invalid_attributes}
      end

      it "assigns the conference as @conference" do
        expect(assigns(:conference)).to eq(conference)
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      expect(conference).to be_present # in these cases, touch it in advance to create it
    end

    it "destroys the requested conference" do
      # preconditions that should be satisfied by setup
      # expect(@current_user.admin?).to be_truthy
      # expect(conference.presentations).to be_empty

      expect {
        delete :destroy, params: {id: conference.to_param}
      }.to change(Conference, :count).by(-1)
    end

    context "with a conference containing presentations" do

      let!(:presentation) { create :presentation, conference_id: conference.id }

      it "does not destroy the requested conference" do
        expect {
          delete :destroy, params: {id: conference.to_param}
        }.not_to change(Conference, :count)

      end
    end

    it "redirects to the events list" do
      delete :destroy, params: {id: conference.to_param}
      expect(response).to redirect_to(events_path)
    end
  end
end
