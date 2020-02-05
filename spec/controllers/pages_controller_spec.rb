require 'rails_helper'

RSpec.describe PassagesController, type: :controller do
  fixtures :roles
  setup :activate_authlogic

  let(:user) { create :user }

  before do
    @current_user = user
    log_in @current_user
  end

  describe "GET #privacy_policy" do

    let!(:passage) { create :passage }

    it "assigns the requested passage as @passage" do
      get :show, params: {id: passage.to_param}
      expect(assigns(:passage)).to eq(passage)
    end
  end
end
