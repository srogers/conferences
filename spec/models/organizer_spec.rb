require 'rails_helper'

RSpec.describe Organizer, type: :model do
  describe "when creating an Organizer" do

    let(:valid_attributes) {
      { name: "Valid Organizer", series_name: "Conference Series", abbreviation: "ConSer" }
    }

    def errors_on_blank(attribute)
      Organizer.create(valid_attributes.merge(attribute => nil)).errors_on(attribute)
    end

    it "should have a working factory" do
      expect(create :organizer).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Organizer.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:name, :series_name, :abbreviation].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

  end
end
