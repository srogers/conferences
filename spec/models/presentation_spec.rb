require 'rails_helper'

RSpec.describe Presentation, type: :model do
  describe "when creating a Presentation" do
    let(:valid_attributes) {
      { name: "Valid Presentation" }
    }

    context "the factory" do
      it "works" do
        expect(create :presentation).to be_valid
      end

      it "works with tags" do
        presentation = create :presentation, tag_list: 'wombats, linoleum'
        expect(presentation).to be_valid
        expect(presentation.tag_list.include?('wombats')).to be_truthy
      end
    end

    it "should be valid with valid attributes" do
      expect(Presentation.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:name].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    context "when the name starts with an article" do
      it "removes the article from name for sortable name" do
        presentation = Presentation.new name: "The Presentation That Shouldn't Be Sorted by T"
        presentation.save
        presentation.reload
        expect(presentation.sortable_name).to eq("Presentation That Shouldn't Be Sorted by T")
      end
    end

    context "when name starts with an article followed by a quote" do
      it "removes the quote from name for sortable name" do
        presentation = Presentation.new name: 'The "Quote" is Not For Sorting'
        presentation.save
        presentation.reload
        expect(presentation.sortable_name).to eq('Quote" is Not For Sorting')
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

    context "with an associated event" do

      let(:conference) { create :conference }

      it "should be valid" do
        expect(Presentation.new(valid_attributes.merge(conference_id: conference.id))).to be_valid
      end

      context "already having a presentation of the same name" do

        let!(:duplicate_presentation) { create :presentation, name: valid_attributes[:name], conference_id: conference.id }

      # This reverses an earlier validation that prevented duplicate names. That seemed like a sensible
      # restriction, but it turns out the be just a pain, because series and tour events sometimes legitimately
      # have presentations with the same name.
      it "can be associated with that conference" do
          presentation = Presentation.create!(valid_attributes.merge(conference_id: conference.id))
          expect(presentation).to be_valid
        end
      end

      context "series" do
        let!(:dummy) { conference.update(event_type: Conference::SERIES) }
        # Only series does this, because for conferences, a presentation date outside the window is probably a user error.
        # A series is always getting new presentations, so it's convenient for the date to just extend automatically.
        it "extends the series start date if the presentation date falls before" do
          presentation = Presentation.new(valid_attributes.merge(conference_id: conference.id, date: conference.start_date - 1.day ))
          expect(presentation).to be_valid
          presentation.save
          expect(presentation.errors).to be_empty
          expect(conference.reload.start_date).to eq(presentation.date)
        end

        it "extends the series end date if the presentation date falls after" do
          presentation = Presentation.new(valid_attributes.merge(conference_id: conference.id, date: conference.end_date + 1.day ))
          expect(presentation).to be_valid
          presentation.save
          expect(presentation.errors).to be_empty
          expect(conference.reload.end_date).to eq(presentation.date)
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

        # This reverses an earlier validation preventing duplicate names, because that restriction is really just unhelpful
        it "can be associated with that conference" do
          presentation.update_attributes!(conference_id: conference.id)
          expect(presentation).to be_valid
        end
      end
    end

    context "changing the name" do
      before do
        presentation.update(name: 'New Presentation Name')
      end

      it "generates a new slug" do
        expect(Presentation.friendly.find('new-presentation-name')).to eq(presentation)
      end

      it "keeps the old slug history" do
        expect(Presentation.friendly.find('some-presentation')).to eq(presentation)
      end
    end
  end

  describe "when destroying a Presentation" do

    let(:presentation) { create :presentation }

    context "with publications" do
      let!(:publication) { create :publication }
      let!(:presentation_publication) { create :presentation_publication, presentation_id: presentation.id, publication_id: publication.id }

      it "also destroys the presentation/publication relationship" do
        presentation.destroy
        expect{ presentation_publication.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not destroy the publication" do
        expect(publication.reload).to be_present
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
