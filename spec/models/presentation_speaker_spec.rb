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

    context "validation" do
      [:presentation_id, :speaker_id].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

  end
end
