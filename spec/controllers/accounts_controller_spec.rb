require 'rails_helper'

describe AccountsController do
  fixtures :roles
  setup :activate_authlogic

  describe "GET show" do
    before do
      @current_user = create :user, role: Role.reader
      log_in @current_user
    end

    it "should assign the current user as @user" do
      get :show
      expect(assigns[:user]).to eq(@current_user)
    end
  end

  describe "GET edit" do
    before do
      @current_user = create :user, role: Role.reader
      log_in @current_user
    end

    it "should assign the current user as @user" do
      get :show
      expect(assigns[:user]).to eq(@current_user)
    end
  end

  describe "PUT update" do
    before do
      @current_user = create :user, role: Role.reader
      log_in @current_user
    end

    it "doesn't allow saving leading or trailing spaces on email or password"

    describe "with valid params" do
      before do
        @valid_params = {name: "New Name", email: "updated@example.com"}
      end

      it "should update the user with params" do
        put :update, params: { :user => @valid_params }
        expect(assigns(:user).name).to eq(@valid_params[:name])
      end

      it "redirects to the account show page" do
        put :update, params: { :user => @valid_params }
        expect(response).to redirect_to account_path
      end
    end

    describe "with invalid params" do
      before do
        @invalid_params = {name: ""}
      end

      it "re-renders the 'edit' template" do
        put :update, params: { :user => @invalid_params }
        expect(response).to render_template 'edit'
      end
    end
  end
end
