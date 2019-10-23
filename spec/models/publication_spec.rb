require 'rails_helper'

RSpec.describe Publication, type: :model do
  describe "create" do

    let(:valid_attributes) { { :format => Publication::CD, name: 'Valid Publication', speaker_names: "Somebody" } }

    def errors_on_blank(attribute)
      Publication.create(valid_attributes.merge(attribute => nil)).errors_on(attribute)
    end

    it "has a working factory" do
      expect(create :publication).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Publication.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:format, :name, :speaker_names].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    it "requires a valid format" do
      expect(Publication.new(valid_attributes.merge(format: "bogosity"))).not_to be_valid
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

    context "with duration" do
      context "blank" do
        it "is valid" do  # Have to allow this, because sometimes we just don't have it
          expect(Publication.new(valid_attributes.merge(duration: nil))).to be_valid
        end
      end

      context "negative" do
        it "is invalid" do
          expect(Publication.new(valid_attributes.merge(duration: -1))).not_to be_valid
        end
      end

      { '18:20': 1100, '8:20': 500, '90': 90, '1:18:20': 78, '01:18:20': 78, '4700': 4700 }.each do |hms, minutes|
        context "from UI as #{hms}" do
          let(:valid_user_attributes) { valid_attributes.merge(ui_duration: hms.to_s)}

          it "is valid" do
            publication = Publication.new(valid_user_attributes)
            expect(publication).to be_valid
          end

          it "saves the duration as #{minutes} minutes" do
            publication = Publication.create(valid_user_attributes)
            expect(publication.errors).to be_empty
            expect(publication.duration).to eq(minutes)
          end
        end
      end

      ['1:70', '01:88:10'].each do |hms|
        context "from UI as #{hms}" do
          let(:valid_user_attributes) { valid_attributes.merge(ui_duration: hms)}

          it "is not valid" do
            publication = Publication.new(valid_user_attributes)
            expect(publication).not_to be_valid
          end
        end
      end

      context "from UI as N/A" do
        let(:valid_user_attributes) { valid_attributes.merge(ui_duration: 'N/A')}

        it "is valid" do
          publication = Publication.new(valid_user_attributes)
          expect(publication).to be_valid
        end
      end

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
