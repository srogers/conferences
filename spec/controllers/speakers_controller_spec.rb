require 'rails_helper'

RSpec.describe SpeakersController, type: :controller do
  fixtures :roles
  fixtures :settings

  # This should return the minimal set of attributes required to create a valid
  # Speaker. As you add validations to Speaker, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: "Valid Speaker" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:speaker) { Speaker.create! valid_attributes }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.reader
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SpeakersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "when listing speakers" do
    it "assigns all speakers as @speakers" do
      get :index, params: {}
      expect(assigns(:speakers)).to eq([speaker])
    end

    context "with a search term" do
      it "finds speakers with matching titles without regard to case" do
        get :index, params:{ search_term: 'VALID' }
        expect(assigns(:speakers)).to eq([speaker])
      end

      it "it doesn't find non-matching speakers" do
        get :index, params:{ search_term: 'Wombats' }
        expect(assigns(:speakers)).to be_empty
      end
    end

    context "with an auto-complete search term" do
      it "finds speakers with titles starting with the search term (case insensitive)" do
        get :index, params:{ q: 'VALID' }
        expect(assigns(:speakers)).to eq([speaker])
      end

      it "finds speakers with interior words starting with the search term" do
        get :index, params:{ q: 'speaker' }
        expect(assigns(:speakers)).to eq([speaker])
      end

      it "it doesn't find non-matching speakers" do
        get :index, params:{ q: 'wombats' }
        expect(assigns(:speakers)).to be_empty
      end

      it "it doesn't find excluded speakers" do
        get :index, params:{ q: 'valid', exclude: speaker.id }
        expect(assigns(:speakers)).to be_empty
      end
    end
  end

  describe "GET #show" do

    let(:user_presentation) { create :user_presentation, user_id: @current_user.id }

    it "assigns the requested speaker as @speaker" do
      get :show, params: {id: speaker.to_param}
      expect(assigns(:speaker)).to eq(speaker)
    end

    it "assigns the current user's presentations" do
      get :show, params: {id: speaker.to_param}
      expect(assigns(:user_presentations)).to eq([user_presentation])
    end

    # This is checked once for all the methods using get_speaker
    context "with a moved speaker" do
      before do
        speaker.update(name: 'New Speaker Name')
      end

      it "finds the speaker with the old URL" do
        get :show, params: {id: 'valid-speaker'}
        expect(assigns(:speaker)).to eq(speaker)
        expect(response).to be_redirect
      end

      it "finds the speaker with the new URL" do
        get :show, params: {id: 'new-speaker-name'}
        expect(assigns(:speaker)).to eq(speaker)
      end
    end
  end

  describe "GET #new" do
    it "redirects" do
      get :new, params: {}
      expect(response).to be_redirected
    end

    context "as an editor" do

      before { assign_role @current_user, Role::EDITOR }

      it "assigns a new speaker as @speaker" do
        get :new, params: {}
        expect(assigns(:speaker)).to be_a_new(Speaker)
      end
    end
  end

  describe "GET #edit" do
    it "assigns the requested speaker as @speaker" do
      get :edit, params: {id: speaker.to_param}
      expect(assigns(:speaker)).to eq(speaker)
    end
  end

  describe "POST #create" do
    it "redirects" do
      get :new, params: {}
      expect(response).to be_redirected
    end

    context "as an editor" do
      context "with valid params" do

        before { assign_role @current_user, Role::EDITOR }

        it "creates a new Speaker" do
          expect {
            post :create, params: {speaker: valid_attributes}
          }.to change(Speaker, :count).by(1)
        end

        it "assigns a newly created speaker as @speaker" do
          post :create, params: {speaker: valid_attributes}
          expect(assigns(:speaker)).to be_a(Speaker)
          expect(assigns(:speaker)).to be_persisted
        end

        it "redirects to the created speaker" do
          post :create, params: {speaker: valid_attributes}
          expect(response).to redirect_to(Speaker.last)
        end

        context "with invalid params" do
          it "assigns a newly created but unsaved speaker as @speaker" do
            post :create, params: {speaker: invalid_attributes}
            expect(assigns(:speaker)).to be_a_new(Speaker)
          end

          it "re-renders the 'new' template" do
            post :create, params: {speaker: invalid_attributes}
            expect(response).to render_template("new")
          end
        end
      end

    end
  end

  describe "PUT #update" do
    it "redirects" do
      get :new, params: {}
      expect(response).to be_redirected
    end

    context "as an editor" do

      before { assign_role @current_user, Role::EDITOR }

      context "with valid params" do
        let(:new_attributes) {
          { name: 'Updated Title' }
        }

        it "updates the requested speaker" do
          expect(speaker.name).to eq('Valid Speaker')
          put :update, params: {id: speaker.to_param, speaker: new_attributes}
          expect(assigns(:speaker).name).to eq(new_attributes[:name])
        end

        it "redirects to the speaker" do
          put :update, params: {id: speaker.to_param, speaker: valid_attributes}
          expect(response).to redirect_to(speaker)
        end
      end

      context "with invalid params" do
        it "assigns the speaker as @speaker" do
          put :update, params: {id: speaker.to_param, speaker: invalid_attributes}
          expect(assigns(:speaker)).to eq(speaker)
        end

        it "re-renders the 'edit' template" do
          put :update, params: {id: speaker.to_param, speaker: invalid_attributes}
          expect(response).to render_template("edit")
        end
      end

    end
  end

  describe "DELETE #destroy" do
    before do
      expect(speaker).to be_present # in these cases, touch it in advance to create it
    end

    it "redirects" do
      get :new, params: {}
      expect(response).to be_redirected
    end

    context "as an editor" do

      before { assign_role @current_user, Role::EDITOR }

      it "destroys the requested speaker" do
        expect {
          delete :destroy, params: {id: speaker.to_param}
        }.to change(Speaker, :count).by(-1)
      end

      context "with owned presentations" do

        let!(:presentation) { create :presentation }
        let!(:presentation_speaker) { create :presentation_speaker, presentation_id: presentation.id, speaker_id: speaker.id }

        it "does not destroy the requested speaker" do
          expect {
            delete :destroy, params: {id: speaker.to_param}
          }.not_to change(Speaker, :count)
        end
      end

      it "redirects to the speakers list" do
        delete :destroy, params: {id: speaker.to_param}
        expect(response).to redirect_to(speakers_url)
      end

    end
  end
end
