require 'rails_helper'

RSpec.describe Organizer, type: :model do
  describe "when creating an Organizer" do

    let(:valid_attributes) {
      { name: "Valid Organizer", series_name: "Conference Series", abbreviation: "ConSer" }
    }

    it "should have a working factory" do
      expect(create :organizer).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Organizer.new(valid_attributes)).to be_valid
    end

    it "requires a name" do
      expect(Organizer.new(valid_attributes.merge(name: ''))).not_to be_valid
    end

    it "requires a series name" do
      expect(Organizer.new(valid_attributes.merge(series_name: ''))).not_to be_valid
    end

    it "requires an abbreviation" do
      expect(Organizer.new(valid_attributes.merge(abbreviation: ''))).not_to be_valid
    end
  end
end
