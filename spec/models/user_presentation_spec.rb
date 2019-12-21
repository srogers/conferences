require 'rails_helper'

RSpec.describe UserPresentation, type: :model do
  describe "when creating a Wishlist" do

    let(:valid_attributes) { { user_id: 1, presentation_id: 1 } }

    def errors_on_blank(attribute)
      UserPresentation.create(valid_attributes.merge(attribute => nil)).errors_on(attribute)
    end

    it "should have a working factory" do
      expect(create :user_presentation).to be_valid
    end

    it "is valid with valid attributes" do
      expect(UserPresentation.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:user_id, :presentation_id].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    context "creating" do
      context "with existing user/presentation entry" do
        before { create :user_presentation }

        it "rejects duplicates" do
          expect{ create :user_presentation }.to raise_error ActiveRecord::RecordNotUnique
        end
      end
    end

  end
end
