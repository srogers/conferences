require 'rails_helper'

RSpec.describe Presentation, type: :model do
  def valid_attributes
    {
        :speaker_id => 1
    }
  end

  describe "when creating a Presentation" do
    it "should have a working factory" do
      expect(create :presentation).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Presentation.new(valid_attributes)).to be_valid
    end

    it "should be invalid without organizer_id" do
      expect(Presentation.new(valid_attributes.merge(speaker_id: nil))).not_to be_valid
    end
  end
end
