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

    context "validation" do
      [:name].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    it "sets the sortable name" do
      speaker = Speaker.new name: "Distinctively Named Speakerperson"
      speaker.save
      speaker.reload
      expect(speaker.sortable_name).to eq('Speakerperson')
    end

    it "capitalizes name" do
      speaker = Speaker.new name: "homer j. simpson"
      speaker.save
      speaker.reload
      expect(speaker.name).to eq('Homer J. Simpson')
    end
  end

  describe "when updating a speaker" do

    let(:speaker) { create :speaker, name: "Original Name" }

    context "changing the name" do
      before do
        speaker.update(name: "Distinctively named Speakerperson")
      end

      it "does not capitalize the name" do
        expect(speaker.name).to eq("Distinctively named Speakerperson")
      end

      it "updates the sortable name" do
        expect(speaker.sortable_name).to eq('Speakerperson')
      end

      it "generates a new slug" do
        expect(Speaker.friendly.find('distinctively-named-speakerperson')).to eq(speaker)
      end

      it "keeps the old slug history" do
        expect(Speaker.friendly.find('original-name')).to eq(speaker)
      end
    end

    context "manually changing the sortable name" do
      before do
        speaker.sortable_name = 'Manually Changed'
      end

      it "retains the change to sortable name" do
        speaker.save
        speaker.reload
        expect(speaker.sortable_name).to eq('Manually Changed')
      end
    end

  end

  describe "finding active years" do

    let(:speaker) { create :speaker }

    it "returns n/a with no presentations" do
      expect(speaker.active_years).to eq('none')
    end

    context "with presentations" do

      let(:first) { create :presentation, date: "1982-03-21".to_date }
      let(:last)  { create :presentation, date: "1997-05-12".to_date }

      let!(:dummy1) { create :presentation_speaker, speaker: speaker, presentation: first }
      let!(:dummy2) { create :presentation_speaker, speaker: speaker, presentation: last }

      it "finds the date of the first and last presentations" do
        expect(speaker.active_years).to eq('1982-1997')
      end
    end
  end
end
