require 'rails_helper'

RSpec.describe PresentationPublication, type: :model do
  describe "when creating a presentation/publication relationship" do

    let(:presentation) { create :presentation }
    let(:user)         { create :user }
    let(:valid_attributes) {
      {
          :presentation_id  => presentation.id,
          :publication_id   => 1,
          :creator_id       => user.id
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

    context "with associated user_presentations", :notifications do

      let!(:user_presentation) { create :user_presentation, presentation_id: presentation.id, user_id: user.id }

      before do
        @mailer_dummy = double(Object, deliver_now: true)
        allow(PublicationNotificationMailer).to receive(:notify).and_return(@mailer_dummy)
      end

      context "and notify_pubs enabled" do

        before do
          user_presentation.update notify_pubs: true
        end

        it "sends user_presentation notifications" do
          expect(PublicationNotificationMailer).to receive(:notify)#.with(user_presentation.user, user_presentation.presentation)
          presentation_publication = PresentationPublication.create(valid_attributes)
          expect(presentation_publication.errors).to be_empty
        end

        it "creates a notification record" do
          presentation_publication = PresentationPublication.create(valid_attributes)
          expect(Notification.where(presentation_publication: presentation_publication, user_presentation: user_presentation).first).to be_present
        end
      end

      context "and notify_pubs disabled" do

        let!(:user_presentation) { create :user_presentation, presentation_id: presentation.id }

        it "does not send user_presentation notifications" do
          expect(PublicationNotificationMailer).not_to receive(:notify)
          presentation_publication = PresentationPublication.create(valid_attributes)
          expect(presentation_publication.errors).to be_empty
        end

        it "does not create notification records" do
          presentation_publication = PresentationPublication.create(valid_attributes)
          expect(Notification.where(presentation_publication: presentation_publication, user_presentation: user_presentation)).to be_empty
        end
      end
    end
  end
end
