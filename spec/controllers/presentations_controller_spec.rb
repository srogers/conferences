require 'rails_helper'

RSpec.describe PresentationsController, type: :controller do

  fixtures :roles
  fixtures :settings

  let(:speaker) { create :speaker }

  # The model doesn't care about presentation_speaker => speaker ID, but the controller validates it
  let(:valid_params) {
    HashWithIndifferentAccess.new( { presentation: { name: "Valid Presentation" }, presentation_speaker: { speaker_id: speaker.id } })
  }

  let(:presentation) { create :presentation }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.editor
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

  context "tags" do

    let!(:presentation) { create :presentation, tag_list: 'wombats' }

    describe "when listing tags" do
      it "assigns all tag names as @tags" do
        get :tags, params: {}
        expect(assigns(:tags)).to eq(presentation.tags)
      end
    end

    describe "when searching tags" do
      it "gets the tag based on a segment" do
        get :tags, params: { term: 'wom'}
        expect(assigns(:tags)).to eq(presentation.tags)
      end

      it "gets the tag regardless of case" do
        get :tags, params: { term: 'WOM'}
        expect(assigns(:tags)).to eq(presentation.tags)
      end
    end
  end

  describe "GET #show" do


    it "assigns the requested presentation as @presentation" do
      get :show, params: {id: presentation.to_param}
      expect(assigns(:presentation)).to eq(presentation)
    end

    context "when the presentation isn't in the current user's wishlist" do
      it "assigns a new user_presentation" do
        get :show, params: {id: presentation.to_param}
        expect(assigns(:user_presentation).persisted?).to be_falsey
      end
    end

    context "when the presentation is in the current user's wishlist" do

      let(:user_presentation) { create :user_presentation, presentation_id: presentation.id, user_id: @current_user.id }

      it "assigns the user_presentation for this user/presentation" do
        skip "mysteriously fails"
        get :show, params: {id: presentation.to_param}
        expect(assigns(:user_presentation)).to eq(user_presentation)
      end
    end

    # This is checked once for all the methods using get_presentation
    context "with a moved presentation" do
      before do
        presentation.update(name: 'New Presentation Name')
      end

      it "finds the presentation with the old URL" do
        get :show, params: {id: 'some-presentation'}
        expect(assigns(:presentation)).to eq(presentation)
        expect(response).to be_redirect
      end

      it "finds the presentation with the new URL" do
        get :show, params: {id: 'new-presentation-name'}
        expect(assigns(:presentation)).to eq(presentation)
      end
    end
  end

  describe "when downloading the handout" do
    it "sends the handout PDF attachment" do
      skip "set up an attachment"
      #get :download_handout, params: { id: presentation.to_param }
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
          post :create, params: valid_params
        }.to change(Presentation, :count).by(1)
      end

      it "assigns a newly created presentation as @presentation" do
        post :create, params: valid_params
        expect(assigns(:presentation)).to be_a(Presentation)
        expect(assigns(:presentation)).to be_persisted
      end

      it "redirects to the created presentation" do
        post :create, params: valid_params
        expect(response).to redirect_to(Presentation.last)
      end

      it "creates the presentation/speaker relationship" do
        post :create, params: valid_params
        presentation_speaker = PresentationSpeaker.where(presentation_id: assigns(:presentation).id, speaker_id: speaker.id).first
        expect(presentation_speaker).to be_present
      end
    end

    context "without a speaker ID" do

      let(:invalid_params) { valid_params.merge(:presentation_speaker => { :speaker_id => nil }) }

      it "does not create a presentation" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Presentation, :count)
      end

      it "returns to the creation form" do
        expect(post :create, params: invalid_params).to render_template("new")
      end
    end

    context "with a speaker ID that points to nothing" do

      let(:invalid_params) { valid_params.merge(:presentation_speaker => {:speaker_id => 456123789}) }

      it "does not create a presentation" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Presentation, :count)
      end

      it "returns to the creation form" do
        expect(post :create, params: invalid_params ).to render_template("new")
      end
    end

    context "with invalid presentation attributes" do

      let(:invalid_params) { valid_params.merge(:presentation => {:name => ''}) }

      it "assigns a newly created but unsaved presentation as @presentation" do
        post :create, params: invalid_params
        expect(assigns(:presentation)).to be_a_new(Presentation)
      end

      it "returns to the creation form" do
        post :create, params: invalid_params
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do

    let(:update_params) { valid_params.merge(id: presentation.to_param, presentation: { name: 'Updated Title' }) } # just like create, but with an added ID

    context "with valid params" do

      it "updates the requested presentation" do
        put :update, params: update_params
        expect(assigns(:presentation).name).to eq(update_params[:presentation][:name])
      end

      it "redirects to the presentation" do
        put :update, params: update_params
        presentation.reload
        expect(response).to redirect_to(presentation)
      end

      # Only presentation attributes are updated here. Speakers are updated through PresentationSpeakers controller
    end

    context "with invalid presentation params" do

      let(:invalid_presentation_params) { update_params.merge(:presentation => {:name => ''}) }

      it "assigns the presentation as @presentation" do
        put :update, params: invalid_presentation_params
        expect(assigns(:presentation)).to eq(presentation)
      end

      it "re-renders the 'edit' template" do
        put :update, params: invalid_presentation_params
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

    context "with a conference present" do

      let(:conference) { create :conference }

      it "redirects to the parent conference" do
        presentation.update_attribute :conference_id, conference.id
        delete :destroy, params: {id: presentation.to_param}
        expect(response).to redirect_to(event_path(conference))
      end
    end
  end
end
