require 'rails_helper'

RSpec.describe User, :type => :model do

  describe "when creating a User" do

    let(:role) { create :role }
    let(:valid_attributes) {
      {
        :name     => 'Generic User',
        :email    => 'testing@example.com',
        :password => 'password1',
        :password_confirmation => 'password1',
        :role     =>  role
      }
    }

    it "should be valid with valid attributes" do
      expect(User.new(valid_attributes)).to be_valid
    end

    it "should have a working factory" do
      expect(create :user).to be_valid
    end

    it "should require a name" do
      expect { User.create! valid_attributes.merge(name: '') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
    end

    it "should require an email" do
      expect { User.create! valid_attributes.merge(email: '') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email should look like an email address.")
    end

    it "cleans the email" do
      user = User.new(valid_attributes.merge(email: ' bob@example.com '))
      user.valid?
      expect(user.email).to eq('bob@example.com')
    end

    it "should require a plausible email" do
      expect { User.create! valid_attributes.merge(email: 'bipity.bop') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email should look like an email address.")
    end

    it "should require matching password and confirmation" do
      expect { User.create! valid_attributes.merge(password: 'bogus', password_confirmation: 'bogosity') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Password is too short (minimum is 7 characters), Password confirmation doesn't match Password")
    end

    it "should require a role" do
      expect(User.new(role_id: nil)).not_to be_valid
    end
  end

  describe "when scoping user" do
    context "by users needing approval" do
      before do
        @user = create :user, approved: false
      end

      it "should find unapproved users" do
        expect(User.needing_approval).to eq([@user])
      end
    end
  end

  describe "when destroying a user" do

    let(:user) { create :user }

    it "handles references to the user as creator"

    context "with conferences" do
      let!(:conference) { create :conference }
      let!(:conference_user) { create :conference_user, conference_id: conference.id, user_id: user.id }

      it "also destroys the conference/user relationship" do
        user.destroy
        expect{ conference_user.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not destroy the conference" do
        user.destroy
        expect(conference.reload).to eq(conference)
      end
    end

  end
end
