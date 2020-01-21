require 'rails_helper'

RSpec.describe Document, type: :model do

  describe "when creating a document" do
    before do
      @document = Document.new # so we see that it's not just the factory setting it
      @document.save
    end

    it "should have a working factory" do
      expect(create :document).to be_valid
    end

    it "sets the initial status to Pending" do
      expect(@document.status).to eq(Document::QUEUED)
    end

    it "sets a default format and option if nothing is set" do
      expect(@document.name).to eq('events.pdf')
    end
  end

end
