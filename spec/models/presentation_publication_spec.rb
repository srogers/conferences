require 'rails_helper'

RSpec.describe PresentationPublication, type: :model do
  describe "when creating a presentation/publication relationship" do

    let(:presentation) { create :presentation }
    let(:valid_attributes) {
      {
          :presentation_id  => presentation.id,
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

    context "with associated user_presentations" do

      let(:user_presentation) { create :user_presentation, presentation_id: presentation.id }

      it "sends user_presentation notificationss" do
        skip "mysteriously doesn't work"
        expect(PublicationNotificationMailer).to receive(:notify)#.with(user_presentation.user, user_presentation.presentation)
        presentation_publication = PresentationPublication.create(valid_attributes)
        expect(presentation_publication.errors).to be_empty
      end
    end
  end
end
