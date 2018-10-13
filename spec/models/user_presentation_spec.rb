require 'rails_helper'

RSpec.describe UserPresentation, type: :model do
  describe "when creating a Wishlist" do

    let(:valid_attributes) { { user_id: 1, presentation_id: 1 } }

    it "should have a working factory" do
      expect(create :user_presentation).to be_valid
    end

    it "is valid with valid attributes" do
      expect(UserPresentation.new(valid_attributes)).to be_valid
    end

    it "requires a valid user" do
      expect(UserPresentation.new(valid_attributes.merge(user_id: nil))).not_to be_valid
    end

    it "requires a valid presentation" do
      expect(UserPresentation.new(valid_attributes.merge(presentation_id: nil))).not_to be_valid
    end
  end
end
