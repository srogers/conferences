require 'rails_helper'

RSpec.describe UserPresentationsController, type: :controller do
  before do
    pretend_to_be_authenticated
    allow(@current_user).to receive(:id).and_return 1
    allow(@current_user).to receive(:id=).and_return true
  end

  let(:presentation) { create :presentation }

  describe "POST #create" do
    before do
      post :create, params: { user_presentation: { presentation_id: presentation.id, user_id: 1 }}
    end

    it "saves the user presentation" do
      expect(assigns(:user_presentation).errors).to be_empty
      expect(assigns(:user_presentation).id).to be_present
    end

    it "redirects to the preesentation page" do
      expect(response).to redirect_to presentation_path(presentation)
    end
  end

  describe "DELETE #destroy" do
    before do
      @user_presentation = create :user_presentation, presentation_id: presentation.id
      delete :destroy, params: {id: @user_presentation.to_param}
    end

    it "finds the presentation/user relationship" do
      expect(assigns(:user_presentation)).to eq(@user_presentation)
    end

    it "destroys the presentation/user relationship" do
      expect { @user_presentation.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "redirects to the presentation" do
      expect(response).to redirect_to presentation_path(presentation)
    end
  end

end
