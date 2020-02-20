require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe "when creating a Notification" do

    let(:valid_attributes) {
      { user_presentation_id: 1, presentation_publication_id: 1 }
    }

    it "should have a working factory" do
      expect(create :notification).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Notification.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:user_presentation_id, :presentation_publication_id].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute, Notification)).to be_present
        end
      end
    end
  end
end
