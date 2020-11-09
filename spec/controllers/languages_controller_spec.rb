require 'rails_helper'

RSpec.describe LanguagesController, type: :controller do
  fixtures :roles
  fixtures :settings

  # This should return the minimal set of attributes required to create a valid
  # Language. As you add validations to Language, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: "Valid Language"}
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:language) { Language.create! valid_attributes }

  setup :activate_authlogic

  before do
    @current_user = create :user, role: Role.admin
    log_in @current_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # LanguagesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "when listing languages" do
    it "assigns all languages as @languages" do
      get :index, params: {}
      expect(assigns(:languages)).to eq([language])
    end
  end

  describe "GET #show" do
    it "assigns the requested language as @language" do
      get :show, params: {id: language.to_param}
      expect(assigns(:language)).to eq(language)
    end
  end

  describe "GET #new" do
    it "assigns a new language as @language" do
      get :new, params: {}
      expect(assigns(:language)).to be_a_new(Language)
    end
  end

  describe "GET #edit" do
    it "assigns the requested language as @language" do
      get :edit, params: {id: language.to_param}
      expect(assigns(:language)).to eq(language)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Language" do
        expect {
          post :create, params: {language: valid_attributes}
        }.to change(Language, :count).by(1)
      end

      it "assigns a newly created language as @language" do
        post :create, params: {language: valid_attributes}
        expect(assigns(:language)).to be_a(Language)
        expect(assigns(:language)).to be_persisted
      end

      it "redirects to the created language" do
        post :create, params: {language: valid_attributes}
        expect(response).to redirect_to(Language.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved language as @language" do
        post :create, params: {language: invalid_attributes}
        expect(assigns(:language)).to be_a_new(Language)
      end

      it "re-renders the 'new' template" do
        post :create, params: {language: invalid_attributes}
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
        put :update, params: {id: language.to_param, language: new_attributes}
      end

      it "updates the requested language" do
        expect(language.name).to eq('Valid Language')
        expect(assigns(:language).name).to eq(new_attributes[:name])
      end

      it "redirects to the language" do
        expect(response).to redirect_to(language)
      end
    end

    context "with invalid params" do
      before do
        put :update, params: {id: language.to_param, language: invalid_attributes}
      end

      it "assigns the language as @language" do
        put :update, params: {id: language.to_param, language: invalid_attributes}
        expect(assigns(:language)).to eq(language)
      end

      it "re-renders the 'edit' template" do
        put :update, params: {id: language.to_param, language: invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      expect(language).to be_present # in these cases, touch it in advance to create it
    end

    it "destroys the requested language" do
      expect {
        delete :destroy, params: {id: language.to_param}
      }.to change(Language, :count).by(-1)
    end

    context "with a publication using language" do

      let!(:publication) { create :publication, language_id: language.id }

      it "does not destroy the requested language" do
        expect {
          delete :destroy, params: {id: language.to_param}
        }.not_to change(Language, :count)

      end
    end

    it "redirects to the languages list" do
      delete :destroy, params: {id: language.to_param}
      expect(response).to redirect_to(languages_url)
    end
  end
end
