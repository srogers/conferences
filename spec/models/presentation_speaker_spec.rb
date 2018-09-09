require 'rails_helper'

RSpec.describe PresentationSpeaker, type: :model do
  describe "when creating a presentation/speaker relationship" do

    let(:valid_attributes) {
      {
        :presentation_id  => 1,
        :speaker_id       => 1,
        :creator_id       => 1
      }
    }

    it "should have a working factory" do
      expect(create :presentation_speaker).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(PresentationSpeaker.new(valid_attributes)).to be_valid
    end

    it "should be invalid without presentation_id" do
      expect(PresentationSpeaker.new(valid_attributes.merge(presentation_id: nil))).not_to be_valid
    end

    it "should be invalid without speaker_id" do
      expect(PresentationSpeaker.new(valid_attributes.merge(speaker_id: nil))).not_to be_valid
    end
  end
end
