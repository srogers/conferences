require 'rails_helper'

RSpec.describe Publication, type: :model do
  describe "create" do

    let(:valid_attributes) { { :format => Publication::CD, name: 'Valid Publication', speaker_names: "Somebody" } }

    it "has a working factory" do
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

    describe "name" do

      let(:attributes) { { speaker_names: 'unspecified', format: Publication::CD } }

      context "starting with an article" do
        it "removes the article from name for sortable name" do
          publication = Publication.new attributes.merge(name: "The Publication That Shouldn't Be Sorted by T")
          publication.save
          publication.reload
          expect(publication.sortable_name).to eq("Publication That Shouldn't Be Sorted by T")
        end
      end

      context "starting with an article followed by a quote" do
        it "removes the quote from name for sortable name" do
          publication = Publication.new attributes.merge(name: 'The "Quote" is Not For Sorting')
          publication.save
          publication.reload
          expect(publication.sortable_name).to eq('Quote" is Not For Sorting')
        end
      end

      context "starting with an quote" do
        it "removes the quote from name for sortable name" do
          publication = Publication.new attributes.merge(name: '"Quote" is Not For Sorting')
          publication.save
          publication.reload
          expect(publication.sortable_name).to eq('Quote" is Not For Sorting')
        end
      end

      context "not starting with an article" do
        it "saves the name directly as sortable name" do
          publication = Publication.new attributes.merge(name: "Creatively Named Publication")
          publication.save
          publication.reload
          expect(publication.sortable_name).to eq("Creatively Named Publication")
        end
      end
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
