require 'rails_helper'

RSpec.describe Conference, type: :model do
  describe "when creating a conference" do

    let(:valid_attributes) {
      {
        :organizer_id => 1,
        :start_date   => '2005/07/15'.to_date,
        :end_date     => '2005/07/23'.to_date
      }
    }

    it "should have a working factory" do
      expect(create :conference).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Conference.new(valid_attributes)).to be_valid
    end

    it "should be invalid without organizer_id" do
      expect(Conference.new(valid_attributes.merge(organizer_id: nil))).not_to be_valid
    end

    it "should be invalid without start_date" do
      expect(Conference.new(valid_attributes.merge(start_date: nil))).not_to be_valid
    end

    it "should be invalid without end_date" do
      expect(Conference.new(valid_attributes.merge(end_date: nil))).not_to be_valid
    end

    it "should be invalid if start_date comes after end_date" do
      expect(Conference.new(valid_attributes.merge(end_date: '2005/07/01'.to_date))).not_to be_valid
    end
  end

  describe "when destroying a conference" do
    let(:conference) { create :conference }

    # Currently, conferences with presentations can't be destroyed - the presentations have to be
    # deleted or unlinked individually.
    # context "with presentations" do
    #   let!(:presentation) { create :presentation, conference_id: conference.id }
    #
    #   it "also destroys the presentations" do
    #     conference.destroy
    #     expect{ presentation.reload }.to raise_error ActiveRecord::RecordNotFound
    #   end
    # end

    context "with users" do
      let!(:user) { create :user }
      let!(:conference_user) { create :conference_user, conference_id: conference.id, user_id: user.id }

      it "also destroys the conference/user relationship" do
        conference.destroy
        expect{ conference_user.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not destroy the user" do
        conference.destroy
        expect(user.reload).to eq(user)
      end
    end

  end
end
