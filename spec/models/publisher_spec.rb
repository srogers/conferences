require 'rails_helper'

RSpec.describe Publisher, type: :model do

  describe "when creating a Publisher" do

    let(:valid_attributes) {
      { :name => "Second Renaissance" }
    }

    it "has a working factory" do
      expect(create :publisher).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Publisher.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:name].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end

      it "rejects duplicate publishers" do
        publisher = create :publisher
        expect {
          duplicate = create :publisher, name: publisher.name
        }.to raise_exception("Validation failed: Name has already been taken")
      end
    end
  end

end
