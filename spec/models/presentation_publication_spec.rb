require 'rails_helper'

RSpec.describe PresentationPublication, type: :model do
  describe "when creating a presentation/publication relationship" do

    let(:valid_attributes) {
      {
          :presentation_id  => 1,
          :publication_id   => 1,
          :creator_id       => 1
      }
    }

    it "should have a working factory" do
      expect(create :presentation_publication).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(PresentationPublication.new(valid_attributes)).to be_valid
    end

    it "should be invalid without presentation_id" do
      expect(PresentationPublication.new(valid_attributes.merge(presentation_id: nil))).not_to be_valid
    end

    it "should be invalid without publication_id" do
      expect(PresentationPublication.new(valid_attributes.merge(publication_id: nil))).not_to be_valid
    end
  end
end
