require 'rails_helper'

RSpec.describe Document, type: :model do

  describe "when creating a document" do
    it "should have a working factory" do
      expect(create :document).to be_valid
    end
  end

end
