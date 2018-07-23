require 'rails_helper'

describe UsersController do
  fixtures :roles, :settings
  setup :activate_authlogic

  let(:valid_attributes) { {
      :name       => "Valid Name",
      :email      => "tester@example.com",
      :password              => 'testing1',
      :password_confirmation => 'testing1',
      :role_id    => Role.reader.id
  } }

  let(:invalid_attributes) { {
      :name       => '',
      :email      => "tester@example.com",
      :password              => 'testing1',
      :password_confirmation => 'testing1',
      :role_id    => Role.reader.id
  } }

  describe "GET index", index: true do
    before do
      @user = create :user, role: Role.admin
      log_in @user
      @user2 = create :user
    end

    it "should assign the results as @users" do
      get :index
      expect(assigns[:users].length).to eq(2)
    end

    context "with unapproved user search" do
      before do
        @user3 = create :user, approved: false
      end

      it "should find unapproved users" do
        get :index, params: { :needs_approval => true }
        expect(assigns[:users]).to eq([@user3])
      end
    end
  end

  describe "when listing supporters" do

    let(:editor_user)        { create :editor_user }
    let(:hidden_editor_user) { create :editor_user, show_contributor: false }

    it "should include editors" do
      get :supporters
      expect(assigns[:editors]).to include(editor_user)
    end

    it "should exclude editors with show_contributor disabled" do
      get :supporters
      expect(assigns[:editors]).not_to include(hidden_editor_user)
    end
  end

  describe "GET show" do
    before do
      @user = create :user, role: Role.admin
      log_in @user
      @user2 = create :user
    end

    it "should assign the results as @user" do
      get :show, params: { id: @user2.to_param }
      expect(assigns[:user]).to eq(@user2)
    end
  end

  describe "when getting the account creation form" do
    context "not logged in" do
      it "sets up the user form" do
        get :new
        expect(assigns(:user)).to be_present
        expect(assigns(:roles)).to be_present
        expect(response).to render_template 'new'
      end
    end

    context "logged in" do
      before do
        @user = create :user, role: Role.reader
        log_in @user
      end

      it "requires a logged in user to be admin" do
        get :new
        expect(response).to redirect_to root_path
      end
    end
  end

  describe "when creating a user" do
    describe "as admin" do
      describe "with valid params" do
        before do
          @user = create :user, role: Role.admin
          log_in @user
        end

        it "creates a new User" do
          expect { post :create, params: { :user => valid_attributes } }.to change(User, :count).by(1)
        end

        it "creates a new User with the specified role" do
          post :create, params: { :user => valid_attributes.merge(role_id: Role.editor.id) }
          expect(assigns(:user).role_name).to eq(Role::EDITOR)
        end

        it "redirects to the users path" do
          post :create, params: { :user => valid_attributes }
          expect(response).to redirect_to users_path
        end
      end

      describe "with invalid params" do
        it "does not create a new User" do
          expect { post :create, params: { :user => invalid_attributes } }.not_to change(User, :count)
        end

        it "re-renders the new template" do
          post :create, params: { :user => invalid_attributes }
          expect(response).to render_template 'new'
        end
      end
    end

    describe "during registration" do
      before do
        log_out  # you are not authenticated
      end

      describe "with valid params" do
        it "creates a new reader User without role params" do
          limited_attributes = valid_attributes
          limited_attributes.delete(:role_id)
          expect { post :create, params: { :user => limited_attributes } }.to change(User, :count).by(1)
          expect(assigns(:user).role_name).to eq(Role::READER)
        end

        it "creates a new User with reader role regardless of the specified role" do
          post :create, params: { :user => valid_attributes.merge(role_id: Role.editor.id) }
          expect(assigns(:user).role_name).to eq(Role::READER)
        end

        it "assigns a newly created user as @user" do
          post :create, params: { :user => valid_attributes }
          expect(assigns(:user)).to be_a(User)
          expect(assigns(:user)).to be_persisted
        end

        it "redirects to the root path" do
          post :create, params: { :user => valid_attributes }
          expect(response).to redirect_to root_path
        end

        it "ensures the email will match a stripped email (actually the user model does this)" do
          post :create, params: { :user => valid_attributes.merge( email: ' bob@example.com ', password: ' tester1 ', password_confirmation: ' tester1 ') }
          puts assigns(:user).errors.full_messages.join(", ") if assigns(:user).errors.present?
          assigns(:user).reload
          expect(assigns(:user).email).to eq('bob@example.com')
        end

        # Since the email/password validation strips spaces, we have to also strip them off during creation, otherwise
        # it would be possible to create a password that never works.
        it "strips leading and trailing spaces off the password" do
          post :create, params: { :user => valid_attributes.merge( email: ' bob@example.com ', password: ' tester1 ') }
          expect(UserSession.new(email: 'bob@example.com', password: 'tester1')).to be_truthy
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved user as @user" do
          post :create, params: { :user => invalid_attributes }
          expect(assigns(:user)).to be_a_new(User)
        end

        it "re-renders the 'new' template" do
          post :create, params: { :user => invalid_attributes }
          expect(response).to render_template 'new'
        end
      end
    end
  end

end
