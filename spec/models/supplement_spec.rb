require 'rails_helper'

RSpec.describe Supplement, type: :model do
  describe "create" do

    let(:valid_attributes) { { name: 'The attachment', description: 'Not blank', url: 'http://www.archive.org/not_blank', conference_id: 1 } }

    it "has a working factory" do
      expect(create :supplement).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Supplement.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:description].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    it "requires either URL or attachment" do
      expect(Supplement.new(valid_attributes.merge(url: nil, attachment: nil))).not_to be_valid
    end

    it "rejects URL and attachment together" do
      skip "set up an attachment"
      # expect(Supplement.new(valid_attributes.merge(url: 'http://www.archive.org/not_blank', attachment: 'not blank'))).not_to be_valid
    end
  end
end

