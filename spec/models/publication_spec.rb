require 'rails_helper'

RSpec.describe Publication, type: :model do
  def valid_attributes
    {
      :presentation_id => 1,
      :format => Publication::CD
    }
  end

  describe "when creating a Publication" do
    it "should have a working factory" do
      expect(create :publication).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Publication.new(valid_attributes)).to be_valid
    end

    it "is invalid without presentation_id" do
      expect(Publication.new(valid_attributes.merge(presentation_id: nil))).not_to be_valid
    end

    it "requires a valid format" do
      expect(Publication.new(valid_attributes.merge(format: "bogosity"))).not_to be_valid
    end
  end
end
