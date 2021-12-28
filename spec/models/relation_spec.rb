require 'rails_helper'

RSpec.describe Relation, :type => :model do

  describe "when creating a Relation" do

    let(:presentation) { create :presentation }
    let(:related)      { create :presentation }
    let(:valid_attributes) {
      { 
        :presentation => presentation,
        :related      => related,
        :kind         => Relation::ABOUT 
      }
    }

    it "has a working factory" do
      expect(create :relation).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Relation.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:presentation_id, :related_id, :kind].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    context "validation" do
      it "requires a legitimate value for kind" do
        expect(Relation.new(valid_attributes.merge(kind: 'Bogus'))).not_to be_valid
      end
    end
  end

  describe "getting presentations" do
    let(:presentation) { create :presentation }
    let(:about_presentation) { create :presentation }
    let(:relationship_type) { Relation::ABOUT }
    # This means presentation is about about_presentation
    let!(:relation) { create :relation, presentation: presentation, related: about_presentation, kind: relationship_type}

    context "about this presentation" do
      let(:relations) { Relation.targeting(about_presentation, relationship_type) }

      it "finds the relation" do
        expect(relations).to eq([relation])
      end

      it "source is the presentation about the given presentation" do
        expect(Relation.source(relations)).to eq([presentation])
      end

      it "target is the given presentation" do
        expect(Relation.target(relations)).to eq([about_presentation])
      end
    end

    context "this presentation is about" do
      let(:relations) { Relation.sourcing(presentation, relationship_type) }

      it "finds the related presentations" do
        expect(relations).to eq([relation])
      end

      it "source is the given presentation" do
        expect(Relation.source(relations)).to eq([presentation])
      end

      it "target is the presentation the given presentation is about" do
        expect(Relation.target(relations)).to eq([about_presentation])
      end
    end
  end
end
