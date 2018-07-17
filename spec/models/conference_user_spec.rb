require 'rails_helper'

RSpec.describe ConferenceUser, type: :model do
  describe "when creating a Conference User" do

    let(:valid_attributes) {
      {
        :conference_id => 1,
        :user_id => 1,
        :creator_id => 1
      }
    }

    it "should have a working factory" do
      expect(create :conference_user).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(ConferenceUser.new(valid_attributes)).to be_valid
    end

    it "should be invalid without conference_id" do
      expect(ConferenceUser.new(valid_attributes.merge(conference_id: nil))).not_to be_valid
    end

    it "should be invalid without user_id" do
      expect(ConferenceUser.new(valid_attributes.merge(user_id: nil))).not_to be_valid
    end
  end
end
