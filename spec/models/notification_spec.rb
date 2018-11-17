require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe "when creating a Notification" do

    let(:valid_attributes) {
      { user_presentation_id: 1, presentation_publication_id: 1 }
    }

    it "should have a working factory" do
      expect(create :notification).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Notification.new(valid_attributes)).to be_valid
    end

    it "requires a user_presentation" do
      expect(Notification.new(valid_attributes.merge(user_presentation_id: ''))).not_to be_valid
    end

    it "requires a presentation_publication" do
      expect(Notification.new(valid_attributes.merge(presentation_publication_id: ''))).not_to be_valid
    end
  end
end
