require 'rails_helper'

RSpec.describe Passage, type: :model do
  describe "when creating a passage" do
    it "creates a valid passage from the factory" do
      passage = create :passage
      expect(passage.errors).to be_empty
    end

    it "ensures presence of name" do
      expect{ create :passage, name: nil }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
    end

    it "ensures presence of content" do
      expect{ create :passage, content: nil }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Content can't be blank")
    end

    it "ensures presence of view" do
      expect{ create :passage, view: nil }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: View can't be blank")
    end

    context "ensures assign var" do
      it "is present" do
        expect{ create :passage, assign_var: nil }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Assign var can't be blank")
      end

      it "is a legal Ruby variable name" do
        expect{ create :passage, assign_var: 'CLASSNAMEZ' }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Assign var must be a legal Ruby variable name")
        expect{ create :passage, assign_var: '1no_number' }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Assign var must be a legal Ruby variable name")
      end
    end

    context "versions" do
      let(:passage) { create :passage }

      it "minor is initialized to zero" do
        expect(passage.minor_version).to eq(0)
      end

      it "major is initialized to one" do
        expect(passage.major_version).to eq(1)
      end
    end
  end

  describe "when updating a passage" do

    let!(:passage) { create :passage }

    context "versions" do
      context "minor update" do

        before do
          passage.update(content: "little tweaks", update_type: Passage::MINOR)
        end

        it "minor is incremented" do
          expect(passage.minor_version).to eq(1)
        end

        it "major is unchanged" do
          expect(passage.major_version).to eq(1)
        end
      end

      context "major update" do
        before do
          passage.update(content: "rewrite", update_type: Passage::MAJOR)
        end

        it "minor is set to zero" do
          expect(passage.minor_version).to eq(0)
        end

        it "major is incremented" do
          expect(passage.major_version).to eq(2)
        end
      end
    end
  end
end
