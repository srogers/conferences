require 'rails_helper'

RSpec.describe PublicationsHelper, type: :helper do

  let(:publication) { create :publication }

  describe "Formatting a publication for display" do
    context "with year specified" do
      it "should generate the text with icon and year" do
        publication.published_on = Date.new(1995)
        expect(helper.format_and_date(publication).include?('CD, 1995')).to be_truthy
      end
    end

    context "with year and URL specified" do
      before do
        publication.url = 'http://example.com'
      end

      it "should generate linked text with icon and year" do
        publication.published_on = Date.new(1995)
        expect(helper.format_and_date(publication).include?('CD')).to be_truthy
        expect(helper.format_and_date(publication).include?('1995')).to be_truthy
        expect(helper.format_and_date(publication).include?('href="http://example.com"')).to be_truthy
      end
    end

    context "without year" do
      it "should not blow up" do
        helper.format_and_date(publication)
        expect(helper.format_and_date(publication).include?('CD')).to be_truthy
      end
    end
  end

end
