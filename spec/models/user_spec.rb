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

    it "is valid with valid attributes" do
      expect(User.new(valid_attributes)).to be_valid
    end

    it "has a working factory" do
      expect(create :user).to be_valid
    end

    it "requires a name" do
      expect { User.create! valid_attributes.merge(name: '') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
    end

    it "requires an email" do
      expect { User.create! valid_attributes.merge(email: '') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email should look like an email address.")
    end

    it "cleans the email" do
      user = User.new(valid_attributes.merge(email: ' bob@example.com '))
      user.valid?
      expect(user.email).to eq('bob@example.com')
    end

    it "requirea a plausible email" do
      expect { User.create! valid_attributes.merge(email: 'bipity.bop') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email should look like an email address.")
    end

    it "requirea matching password and confirmation" do
      expect { User.create! valid_attributes.merge(password: 'robosity', password_confirmation: 'bogosity') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Password confirmation doesn't match Password")    end

    it "requires a role" do
      expect(User.new(role_id: nil)).not_to be_valid
    end

    it "sets the sortable name" do
      speaker = Speaker.new name: "Distinctively Named Speakerperson"
      speaker.save
      speaker.reload
      expect(speaker.sortable_name).to eq('Speakerperson')
    end
  end

  describe "when approved by admin" do

    let(:user) { create :user, approved: false }

    it "does not change the perishable token value" do
      initial_token = user.perishable_token
      user.approve!
      expect(user.reload.perishable_token).to eq(initial_token)
    end

    it "approves the user" do
      user.approve!
      expect(user.reload).to be_approved
    end
  end

  describe "when scoping user" do
    context "by users needing approval" do

      let(:user) { create :user, approved: false }

      it "should find unapproved users" do
        expect(User.needing_approval).to eq([user])
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

  describe "when updating a user" do

    let(:user) { create :user, name: "Original Name" }

    context "changing the name" do
      before do
        user.update(name: "Distinctively named Userperson")
      end

      it "updates the sortable name" do
        expect(user.sortable_name).to eq('Userperson')
      end
    end

    context "manually changing the sortable name" do
      before do
        user.sortable_name = 'Manually Changed'
      end

      it "retains the change to sortable name" do
        user.save
        user.reload
        expect(user.sortable_name).to eq('Manually Changed')
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
