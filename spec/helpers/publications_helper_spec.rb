require 'rails_helper'

RSpec.describe PublicationsHelper, type: :helper do
  fixtures :roles

  setup :activate_authlogic

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

  describe "when formatting times" do
    context "with current_user" do
      before do
        @current_user = create :user, role: Role.reader, time_zone: "Central Time (US & Canada)"
        log_in @current_user
      end

      context "with hh:mm time format preference" do

        before { @current_user.update_attribute :time_format, Publication::HMS }

        it "converts to hh:mm" do
          expect(helper.formatted_time(23)).to eq("00:23")
          expect(helper.formatted_time(60)).to eq("01:00")
          expect(helper.formatted_time(61)).to eq("01:01")
          expect(helper.formatted_time(360)).to eq("06:00")
          expect(helper.formatted_time(364)).to eq("06:04")
        end
      end

      context "with minutes time format preference" do

        before { @current_user.update_attribute :time_format, Publication::MINUTES }

        it "converts to minutes" do
          expect(helper.formatted_time(23)).to eq("23")
          expect(helper.formatted_time(60)).to eq("60")
          expect(helper.formatted_time(360)).to eq("360")
          expect(helper.formatted_time(364)).to eq("364")
          expect(helper.formatted_time(3600)).to eq("3600")
          expect(helper.formatted_time(3643)).to eq("3643")
        end
      end
    end

    context "without current user" do
      it "converts to hh:mm" do
        expect(helper.formatted_time(61)).to eq("01:01")
      end
    end
  end

  describe "when unformatting times" do
    it "converts hh:mm to minutes" do
      expect(helper.unformatted_time("00:23")).to eq(23)
      expect(helper.unformatted_time("01:00")).to eq(60)
      expect(helper.unformatted_time("06:00")).to eq(360)
      expect(helper.unformatted_time("06:04")).to eq(364)
    end

    it "converts m:ss to minutes" do
      expect(helper.unformatted_time("0:23")).to eq(23)
      expect(helper.unformatted_time("1:00")).to eq(60)
      expect(helper.unformatted_time("6:00")).to eq(360)
    end

    it "converts hh:mm:ss to rounded minutes" do
      expect(helper.unformatted_time("01:00:00")).to eq(60)
      expect(helper.unformatted_time("01:00:43")).to eq(61)
    end

    it "converts h:mm:ss to seconds" do
      expect(helper.unformatted_time("1:00:00")).to eq(60)
      expect(helper.unformatted_time("1:00:43")).to eq(61)
    end

  end

end
