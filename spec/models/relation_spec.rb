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
  end

  describe "getting presentations" do
    let(:presentation) { create :presentation }
    let(:about_presentation) { create :presentation }
    let!(:relation) { create :relation, presentation: presentation, related: about_presentation, kind: Relation::ABOUT }

    context "about this presentation" do
      it "finds the related presentations" do
        expect(Relation.about_this(about_presentation)).to eq([presentation])
      end
    end

    context "this presentation is about" do
      it "finds the related presentations" do
        expect(Relation.this_is_about(presentation)).to eq([about_presentation])
      end
    end
  end
end
