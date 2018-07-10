require 'rails_helper'

RSpec.describe Presentation, type: :model do
  def valid_attributes
    {
      name: "Valid Presentation"
    }
  end

  describe "when creating a Presentation" do
    it "should have a working factory" do
      expect(create :presentation).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Presentation.new(valid_attributes)).to be_valid
    end

    it "requires a name" do
      expect(Presentation.new(valid_attributes.merge(name: ''))).not_to be_valid
    end
  end
end
