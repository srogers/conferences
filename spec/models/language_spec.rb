require 'rails_helper'

RSpec.describe Language, type: :model do
  describe "when creating a Language" do

    let(:valid_attributes) {
      { name: "English" }
    }

    it "should have a working factory" do
      expect(create :language).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Language.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:name].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

  end
end
