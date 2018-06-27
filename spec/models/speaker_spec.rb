require 'rails_helper'

RSpec.describe Speaker, type: :model do
  def valid_attributes
    {
    }
  end

  describe "when creating a Speaker" do
    it "should have a working factory" do
      expect(create :speaker).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Speaker.new(valid_attributes)).to be_valid
    end
  end
end
