require 'rails_helper'

RSpec.describe Role, :type => :model do
  fixtures :roles

  describe "when creating a Role" do

    let(:valid_attributes) {
      { :name => Role::ADMIN }
    }

    def errors_on_blank(attribute, blankish = nil)
      Role.create(valid_attributes.merge(attribute => blankish)).errors_on(attribute)
    end

    it "has a working factory" do
      expect(create :role).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Role.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:name].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end
  end

  describe "when finding roles for assignment" do
    it "finds admin" do
      expect(Role.admin).to be_present
    end

    it "finds editor" do
      expect(Role.editor).to be_present
    end

    it "finds reader" do
      expect(Role.reader).to be_present
    end
  end
end
