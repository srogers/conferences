require 'rails_helper'

RSpec.describe Conference, type: :model do
  def valid_attributes
    {
      :organizer_id => 1,
      :start_date   => '2005/07/15'.to_date,
      :end_date     => '2005/07/23'.to_date
    }
  end

  describe "when creating a Conference" do
    it "should have a working factory" do
      expect(create :conference).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Conference.new(valid_attributes)).to be_valid
    end

    it "should be invalid without organizer_id" do
      expect(Conference.new(valid_attributes.merge(organizer_id: nil))).not_to be_valid
    end

    it "should be invalid without start_date" do
      expect(Conference.new(valid_attributes.merge(start_date: nil))).not_to be_valid
    end

    it "should be invalid without end_date" do
      expect(Conference.new(valid_attributes.merge(end_date: nil))).not_to be_valid
    end
  end
end
