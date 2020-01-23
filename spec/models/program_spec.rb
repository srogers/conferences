require 'rails_helper'

RSpec.describe Program, type: :model do
  describe "create" do

    let(:valid_attributes) { { name: 'The attachment', description: 'Not blank', url: 'http://www.archive.org/not_blank', conference_id: 1 } }

    def errors_on_blank(attribute)
      Program.create(valid_attributes.merge(attribute => nil)).errors_on(attribute)
    end

    it "has a working factory" do
      expect(create :program).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Program.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:description].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    it "requires either URL or program attachment" do
      expect(Program.new(valid_attributes.merge(url: nil, attachment: nil))).not_to be_valid
    end

    it "rejects both URL and program attachment together" do
      skip "set up an attachment"
      # expect(Program.new(valid_attributes.merge(url: 'http://www.archive.org/not_blank', attachment: 'not blank'))).not_to be_valid
    end
  end
end

