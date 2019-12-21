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
    # Make sure these already exist, because we're going to find or not find them
    let!(:user)  { create :admin_user }
    let!(:user2) { create :user }
    let!(:user3) { create :user, approved: false }

    context "as admin" do
      before { log_in user }

      it "should assign the results as @users" do
        get :index

        expect(assigns[:users]).to include(user)   # I can see myself!
        expect(assigns[:users]).to include(user2)  # I see other users
      end

      context "with unapproved user search" do

        it "should find unapproved users" do
          get :index, params: { :needs_approval => true }

          expect(assigns[:users]).to eq([user3])  # I see just this one
        end
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
    let!(:user)  { create :admin_user }
    let!(:user2) { create :user }

    context "as admin" do
      before { log_in user }

      it "should assign the results as @user" do
        get :show, params: { id: user2.to_param }

        expect(assigns[:user]).to eq(user2)
      end
    end
  end

  describe "GET events" do
    let(:user)             { create :reader_user }
    let(:conference)       { create :conference }
    let!(:conference_user) { create :conference_user, user_id: user.id, conference_id: conference.id }

    context "for the current user" do
      before { log_in user }

      context "implicitly by omission" do
        it "finds the current user's events" do
          get :events

          expect(assigns[:conferences]).to eq(user.conferences)
        end
      end

      context "explicitly via a user_id that is the current user" do
        # A user can get here in the UI by clicking on themselves in the attendee list
        it "finds the user's own events" do
          get :events, params: { user_id: @current_user.to_param }

          expect(assigns[:conferences]).to eq([conference])
        end
      end

      context "with attendance privacy enabled" do
        before { user.update!(show_attendance: false) }

        it "still finds the specified user's own events" do
          get :events

          expect(assigns[:conferences]).to eq([conference])
        end
      end

    end

    context "with no current user" do
      before do
        log_out                      # you are not authenticated
        pretend_to_be_logged_out     # block any current_user or session that might be hanging around
      end

      context "for a specified user" do
        context "with attendance privacy enabled" do
          before { user.update!(show_attendance: false) }

          it "does not find the specified user's events" do
            get :events, params: { user_id: user.to_param }

            expect(assigns[:conferences]).to be_nil
            expect(response).to redirect_to root_path
          end
        end

        context "with attendance privacy disabled" do
          before { user.update!(show_attendance: true) }

          it "finds the specified user's events" do
            get :events, params: { user_id: user.to_param }

            expect(assigns[:conferences]).to eq([conference])
          end
        end

        context "that doesn't exist" do
          before { user.update!(show_attendance: false) }

          it "finds nothing and redirects" do
            get :events, params: { user_id: '9999' }

            expect(assigns[:conferences]).to be_nil
            expect(response).to redirect_to root_path
          end
        end
      end
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
      let!(:reader_user)  { create :reader_user }

      context "as reader" do
        before { log_in reader_user }

        it "requires admin user" do
          get :new

          expect(response).to redirect_to root_path
        end
      end

    end
  end

  describe "when creating a user" do
    let!(:user)  { create :admin_user }

    context "as admin" do
      before { log_in user }

      describe "with valid params" do
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

      # Currently not in effect
      # describe "with a GDPR country" do
      #   before do
      #     post :create, params: { :user => valid_attributes.merge(country: "EE") }
      #   end
      #
      #   it "redirects to the root path" do
      #     expect(response).to redirect_to root_path
      #   end
      #
      #   it "sets a flash message" do
      #     expect(flash[:notice]).to eq("This site does not support accounts from that country at this time.")
      #   end
      # end

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
        log_out                      # you are not authenticated
        pretend_to_be_logged_out     # block any current_user or session that might be hanging around
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

      # Currently not restricted
      # describe "with a GDPR country" do
      #   before do
      #     post :create, params: { :user => valid_attributes.merge(country: "EE") }
      #   end
      #
      #   it "redirects to the root path" do
      #     expect(response).to redirect_to root_path
      #   end
      #
      #   it "sets a flash message" do
      #     expect(flash[:notice]).to eq("This site does not support accounts from that country at this time.")
      #   end
      # end

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

  # This gets spec'd at both the model and controller level, because it's super-annoying if it's broken
  describe "when approving a user" do
    let(:admin) { create :admin_user }
    let!(:user) { create :user, approved: false }

    context "as admin" do
      before { log_in admin }

      it "approves the specified user" do
        put :approve, params: {id: user.to_param}
        expect(user.reload).to be_approved
      end

      it "does not change the perishable token value" do
        initial_token = user.perishable_token
        put :approve, params: {id: user.to_param}
        expect(user.reload.perishable_token).to eq(initial_token)
      end

      it "redirects to the list of users needing approval" do
        put :approve, params: {id: user.to_param}
        expect(response).to redirect_to users_path(needs_approval: true)
      end
    end
  end

end
