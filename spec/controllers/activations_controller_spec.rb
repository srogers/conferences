require 'rails_helper'

describe ActivationsController do

  fixtures :settings

  let(:user) { instance_double User }

  describe "GET create (activation)" do
    context "with valid token and inactive user" do
      before do
        allow(User).to receive(:find_using_perishable_token).and_return user
        allow(user).to receive(:active?).and_return false
        allow(user).to receive(:approve!).and_return true
        allow(user).to receive(:activate!).and_return true
      end

      it "should find the user by token" do
        expect(User).to receive(:find_using_perishable_token).and_return user
        post :create, params: { id: 'token' }
      end

      context "when account approval is required" do
        before do
          allow(Setting).to receive(:require_account_approval?).and_return true
          allow(AccountCreationMailer).to receive_message_chain(:pending_activation_notice, :deliver_now).and_return true
        end

        it "activates the user" do
          expect(user).to receive(:activate!)
          post :create, params: { id: 'token' }
        end

        it "redirects to the root path" do
          post :create, params: { id: 'token' }
          expect(response).to redirect_to root_path
        end
      end

      context "when account approval is not required" do
        before do
          allow(Setting).to receive(:require_account_approval?).and_return false
          expect(AccountCreationMailer).not_to receive(:pending_activation_notice)
          allow(UserSession).to receive(:create).with(user, false)
        end

        context "and user is already activated" do
          before do
            allow(user).to receive(:active?).and_return true
            expect(user).not_to receive(:activate!)
          end

          it "should approve the user" do
            expect(user).to receive(:approve!)
            post :create, params: { id: 'token' }
          end

          it "should log the user in" do
            expect(UserSession).to receive(:create).with(user, false)
            post :create, params: { id: 'token' }
          end

          it "redirects to the account page" do
            post :create, params: { id: 'token' }
            expect(response).to redirect_to account_path
          end
        end
      end

      context "when user is already activated" do
        before do
          allow(user).to receive(:active?).and_return true
        end

        it "does not re-activate the user" do
          expect(user).not_to receive(:activate!)
          post :create, params: { id: 'token' }
        end
      end
    end

    context "with invalid token" do
      before do
        allow(User).to receive(:find_using_perishable_token).and_return nil
      end

      it "redirects to the root path" do
        post :create, params: { id: 'token' }
        expect(response).to redirect_to root_path
      end
    end
  end
end
