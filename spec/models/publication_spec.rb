require 'rails_helper'

RSpec.describe Publication, type: :model do
  describe "when creating a Publication" do

    let(:valid_attributes) { { :format => Publication::CD, name: 'Valid Publication', speaker_names: "Somebbody" } }

    it "should have a working factory" do
      expect(create :publication).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Publication.new(valid_attributes)).to be_valid
    end

    it "requires a valid format" do
      expect(Publication.new(valid_attributes.merge(format: "bogosity"))).not_to be_valid
    end

    it "requires a name" do
      expect(Publication.new(valid_attributes.merge(name: ""))).not_to be_valid
    end

    it "requires a speaker name" do
      expect(Publication.new(valid_attributes.merge(speaker_names: ""))).not_to be_valid
    end
  end

  describe "when destroying a Publication" do

    let(:publication) { create :publication }

    context "with associated presentations" do
      let!(:presentation) { create :presentation }
      let!(:presentation_publication) { create :presentation_publication, presentation_id: presentation.id, publication_id: publication.id }

      it "also destroys the presentation/publication relationship" do
        publication.destroy
        expect{ presentation_publication.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not destroy the presentation" do
        expect(presentation.reload).to be_present
      end
    end
  end
end
