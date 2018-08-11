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

    context "when the name starts with an article" do
      it "removes the article from name for sortable name" do
        presentation = Presentation.new name: "The Presentation That Shouldn't Be Sorted by T"
        presentation.save
        presentation.reload
        expect(presentation.sortable_name).to eq("Presentation That Shouldn't Be Sorted by T")
      end
    end

    context "when the name starts with an quote" do
      it "removes the quote from name for sortable name" do
        presentation = Presentation.new name: '"Quote" is Not For Sorting'
        presentation.save
        presentation.reload
        expect(presentation.sortable_name).to eq('Quote" is Not For Sorting')
      end
    end

    context "when the name does not start with an article" do
      it "saves the name directly as sortable name" do
        presentation = Presentation.new name: "Creatively Named Presentation"
        presentation.save
        presentation.reload
        expect(presentation.sortable_name).to eq("Creatively Named Presentation")
      end
    end
    # Requiring a speaker is managed by the controller

    context "with an associated conference" do

      let(:conference) { create :conference }

      it "should be valid" do
        expect(Presentation.new(valid_attributes.merge(conference_id: conference.id))).to be_valid
      end

      context "already having a presentation of the same name" do

        let!(:duplicate_presentation) { create :presentation, name: valid_attributes[:name], conference_id: conference.id }

        it "can't be associated with that conference" do
          expect { Presentation.create!(valid_attributes.merge(conference_id: conference.id)) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Conference already has a presentation with the same name.")
        end
      end
    end
  end

  describe "when updating a Presentation" do

    let!(:presentation) { create :presentation }

    context "conference" do

      let(:conference) { create :conference }

      # Need to be sure the duplicate validator doesn't fail by finding itself
      it "associates the presentation with the conference" do
        presentation.update conference_id: conference.id
        expect(presentation.reload.conference).to eq(conference)
      end

      # This validator is checked in both create and update because it runs differently based on id presence
      context "with a conference having a presentation of the same name" do

        let!(:duplicate_presentation) { create :presentation, name: presentation.name, conference_id: conference.id }

        it "can't be associated with that conference" do
          expect { presentation.update_attributes!(conference_id: conference.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Conference already has a presentation with the same name.")
        end
      end
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
