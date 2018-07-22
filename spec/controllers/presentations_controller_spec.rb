require 'rails_helper'

RSpec.describe PresentationsController, type: :controller do
  fixtures :roles
  fixtures :settings

  # This should return the minimal set of attributes required to create a valid
  # Presentation. As you add validations to Presentation, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: "Valid Presentation" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:presentation) { Presentation.create! valid_attributes }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.admin
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PresentationsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "when listing presentations" do
    it "assigns all presentations as @presentations" do
      skip "works but not in Rspec"
      get :index, params: {}
      expect(assigns(:presentations)).to eq([presentation])
    end

    context "with a search term" do
      it "finds presentations with matching titles without regard to case" do
        skip "works but not in Rspec"
        get :index, params:{ search_term: 'VALID' }
        expect(assigns(:presentations)).to eq([presentation])
      end

      it "skip presentations with matching interior text" do
        skip "works but not in Rspec"
        get :index, params:{ search_term: 'resent' }
        expect(assigns(:presentations)).to eq([presentation])
      end

      it "it doesn't find non-matching presentations" do
        get :index, params:{ search_term: 'Wombats' }
        expect(assigns(:presentations)).to be_empty
      end
    end

    context "with an auto-complete search term" do
      it "finds presentations with titles starting with the search term (case insensitive)" do
        skip "works but not in Rspec"
        get :index, params:{ q: 'VALID', per: 5 }
        expect(assigns(:presentations)).to eq([presentation])
      end

      it "finds presentations with interior words starting with the search term" do
        skip "works but not in Rspec"
        get :index, params:{ q: 'present', per: 5 }
        expect(assigns(:presentations)).to eq([presentation])
      end

      it "it doesn't find non-matching presentations" do
        get :index, params:{ q: 'wombats', per: 5 }
        expect(assigns(:presentations)).to be_empty
      end

      it "returns the right JSON elements"
    end

    context "by tag" do
      before do
        @tagged_presentation = create :presentation
        @tagged_presentation.tag_list.add("history")
        @tagged_presentation.save
      end

      it "shows the relevant presentations" do
        get :index, params: { tag: 'history' }
        expect(assigns(:presentations)).to match_array([@tagged_presentation]) # but not @presentation
      end
    end
  end

  describe "when listing tags" do

    let!(:presentation) { create :presentation, tag_list: 'wombats' }

    it "assigns all tag names as @tags" do
      skip "works but not in Rspec"
      get :index, params: {}
      expect(assigns(:tags)).to eq(['wombats'])
    end
  end

  describe "GET #show" do
    it "assigns the requested presentation as @presentation" do
      get :show, params: {id: presentation.to_param}
      expect(assigns(:presentation)).to eq(presentation)
    end
  end

  describe "GET #new" do
    it "assigns a new presentation as @presentation" do
      get :new, params: {}
      expect(assigns(:presentation)).to be_a_new(Presentation)
    end

    context "with an identified conference" do

      let(:conference) { create :conference }

      it "assigns the conference to the the new presentation" do
        get :new, params: { conference_id: conference.id }
        expect(assigns(:presentation).conference).to eq(conference)
      end
    end
  end

  describe "GET #edit" do
    it "assigns the requested presentation as @presentation" do
      get :edit, params: {id: presentation.to_param}
      expect(assigns(:presentation)).to eq(presentation)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Presentation" do
        expect {
          post :create, params: {presentation: valid_attributes}
        }.to change(Presentation, :count).by(1)
      end

      it "assigns a newly created presentation as @presentation" do
        post :create, params: {presentation: valid_attributes}
        expect(assigns(:presentation)).to be_a(Presentation)
        expect(assigns(:presentation)).to be_persisted
      end

      it "redirects to the created presentation" do
        post :create, params: {presentation: valid_attributes}
        expect(response).to redirect_to(Presentation.last)
      end

      it "creates the presentation/speaker relationship"

      it "requires a presentation/speaker relationship"  # TODO - this seems like a good idea
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved presentation as @presentation" do
        post :create, params: {presentation: invalid_attributes}
        expect(assigns(:presentation)).to be_a_new(Presentation)
      end

      it "re-renders the 'new' template" do
        post :create, params: {presentation: invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { name: 'Updated Title' }
      }

      it "updates the requested presentation" do
        expect(presentation.name).to eq('Valid Presentation')
        put :update, params: {id: presentation.to_param, presentation: new_attributes}
        expect(assigns(:presentation).name).to eq(new_attributes[:name])
      end

      it "redirects to the presentation" do
        put :update, params: {id: presentation.to_param, presentation: valid_attributes}
        expect(response).to redirect_to(presentation)
      end
    end

    context "with invalid params" do
      it "assigns the presentation as @presentation" do
        put :update, params: {id: presentation.to_param, presentation: invalid_attributes}
        expect(assigns(:presentation)).to eq(presentation)
      end

      it "re-renders the 'edit' template" do
        put :update, params: {id: presentation.to_param, presentation: invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      expect(presentation).to be_present # in these cases, touch it in advance to create it
    end

    it "destroys the requested presentation" do
      expect {
        delete :destroy, params: {id: presentation.to_param}
      }.to change(Presentation, :count).by(-1)
    end

    it "redirects to the presentations list" do
      delete :destroy, params: {id: presentation.to_param}
      expect(response).to redirect_to(presentations_url)
    end
  end
end
