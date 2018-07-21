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

  describe "when an admin takes over a user's assets (prior to destroy)" do

    let(:user) { create :user, approved: false }    # user has to be deactivated before pwnd!
    let(:deleting_admin) { create :admin_user }

    context "with created conferences" do

      let!(:conference) { create :conference, creator_id: user.id }

      it "assigns created conference to the deleting admin" do
        results = user.pwnd! deleting_admin
        expect(results).to be_truthy
        expect(conference.reload.creator).to eq(deleting_admin)
      end

      context "when user is still active" do
        before do
          user.approve!
          @results = user.pwnd! deleting_admin
        end

        it "returns false" do
          expect(@results).to be_falsey
        end

        it "leaves created conference assigned to the user" do
          expect(conference.reload.creator).to eq(user)
        end
      end
    end

    context "with created presentations" do

      let!(:presentation) { create :presentation, creator_id: user.id }

      it "assigns created presentation to the deleting admin" do
        results = user.pwnd! deleting_admin
        expect(results).to be_truthy
        expect(presentation.reload.creator).to eq(deleting_admin)
      end

      context "when user is still active" do
        before do
          user.approve!
          @results = user.pwnd! deleting_admin
        end

        it "returns false" do
          expect(@results).to be_falsey
        end

        it "leaves created presentation assigned to the user" do
          expect(presentation.reload.creator).to eq(user)
        end
      end
    end

    context "with created speakers" do

      let!(:speaker) { create :speaker, creator_id: user.id }

      it "assigns created speaker to the deleting user" do
        results = user.pwnd! deleting_admin
        expect(results).to be_truthy
        expect(speaker.reload.creator).to eq(deleting_admin)
      end

      context "when user is still active" do
        before do
          user.approve!
          @results = user.pwnd! deleting_admin
        end

        it "returns false" do
          expect(@results).to be_falsey
        end

        it "leaves created speaker assigned to the user" do
          expect(speaker.reload.creator).to eq(user)
        end
      end
    end

    context "with created publications" do

      let!(:publication) { create :publication, creator_id: user.id }

      it "assigns created publication to the deleting user" do
        results = user.pwnd! deleting_admin
        expect(results).to be_truthy
        expect(publication.reload.creator).to eq(deleting_admin)
      end

      context "when user is still active" do
        before do
          user.approve!
          @results = user.pwnd! deleting_admin
        end

        it "returns false" do
          expect(@results).to be_falsey
        end

        it "leaves created publication assigned to the user" do
          expect(publication.reload.creator).to eq(user)
        end
      end
    end

    context "with created presentation_speakers" do

      let!(:presentation_speaker) { create :presentation_speaker, creator_id: user.id }

      it "assigns created presentation_speaker to the deleting user" do
        results = user.pwnd! deleting_admin
        expect(results).to be_truthy
        expect(presentation_speaker.reload.creator).to eq(deleting_admin)
      end

      context "when user is still active" do
        before do
          user.approve!
          @results = user.pwnd! deleting_admin
        end

        it "returns false" do
          expect(@results).to be_falsey
        end

        it "leaves created presentation_speaker assigned to the user" do
          expect(presentation_speaker.reload.creator).to eq(user)
        end
      end
    end
  end

  describe "when destroying a user" do

    let(:user) { create :user }

    context "with attended conferences" do
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
