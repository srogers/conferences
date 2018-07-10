require 'rails_helper'

RSpec.describe Organizer, type: :model do
  def valid_attributes
    {
      name: "Valid Organizer"
    }
  end

  describe "when creating a Organizer" do
    it "should have a working factory" do
      expect(create :organizer).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Organizer.new(valid_attributes)).to be_valid
    end

    it "requires a name" do
      expect(Organizer.new(valid_attributes.merge(name: ''))).not_to be_valid
    end
  end
end
