require 'rails_helper'

RSpec.describe Speaker, type: :model do
  describe "when creating a Speaker" do

    let(:valid_attributes) {
      { name: "Testing Userperson" }
    }

    it "should have a working factory" do
      expect(create :speaker).to be_valid
    end

    it "should be valid with valid attributes" do
      expect(Speaker.new(valid_attributes)).to be_valid
    end

    it "requires a name" do
      expect(Speaker.new(valid_attributes.merge(name: ''))).not_to be_valid
    end

    it "sets the sortable name" do
      speaker = Speaker.new name: "Distinctively Named Speakerperson"
      speaker.save
      speaker.reload
      expect(speaker.sortable_name).to eq('Speakerperson')
    end
  end

  describe "when updating a speaker" do
    it "updates the sortable name" do
      speaker = create :speaker
      speaker.name = "Distinctively Named Speakerperson"
      speaker.save
      speaker.reload
      expect(speaker.sortable_name).to eq('Speakerperson')
    end
  end
end
