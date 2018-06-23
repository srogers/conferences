require 'rails_helper'

RSpec.describe Role, :type => :model do
  fixtures :roles

  def valid_attributes
    {
      :name => Role::ADMIN
    }
  end

  describe "when creating a Role" do
    it "should have a working factory" do
      expect(create :role).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Role.new(valid_attributes)).to be_valid
    end

    it "should be invalid with bogus attributes" do
      expect(Role.new(name: 'bogus')).not_to be_valid
    end
  end

  describe "when finding roles for assignment" do
    it "should find admin" do
      expect(Role.admin).to be_present
    end

    it "should find editor" do
      expect(Role.editor).to be_present
    end

    it "should find reader" do
      expect(Role.reader).to be_present
    end
  end
end
