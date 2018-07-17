require 'rails_helper'

RSpec.describe Presentation, type: :model do
  describe "when creating a Presentation" do
    let(:valid_attributes) {
      { name: "Valid Presentation" }
    }

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

  describe "when destroying a Presentation" do

    let(:presentation) { create :presentation }

    context "with publications" do
      let!(:publication) { create :publication, presentation_id: presentation.id }

      it "also destroys the publications" do
        presentation.destroy
        expect{ publication.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "with speakers" do
      let!(:speaker) { create :speaker }
      let!(:presentation_speaker) { create :presentation_speaker, presentation_id: presentation.id, speaker_id: speaker.id }

      it "also destroys the presentation/speaker relationship" do
        presentation.destroy
        expect{ presentation_speaker.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not destroy the speaker" do
        presentation.destroy
        expect(speaker.reload).to eq(speaker)
      end
    end
  end
end
