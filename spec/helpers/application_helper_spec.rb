require 'rails_helper'

# Specs in this file have access to a helper object that includes the ApplicationHelper.

describe ApplicationHelper do
  fixtures :roles
  setup :activate_authlogic

  context "when formatting dates" do
    before do
      # A Time like this could come from a form filled out by the user with local time
      @basis     = "2016-07-29T11:22:45-05:00".to_datetime
      # Expected format of all the DB times - stored in UTC
      @basis_utc = "2016-07-29T16:22:45+00:00".to_datetime
    end

    context "with current_user" do
      before do
        @current_user = create :user, role: Role.reader, time_zone: "Central Time (US & Canada)"
        log_in @current_user
      end

      context "and defined time zone" do
        it "should have central time configured in spec helper" do
          expect(@current_user.time_zone).to eq("Central Time (US & Canada)")
        end

        it "should localize correctly when specified" do
          expect(helper.pretty_date(@basis_utc, localize: true, style: :full)).to eq("07/29/16 11:22 AM")
        end

        it "should convert localized by default" do
          expect(helper.pretty_date(@basis_utc, style: :full)).to eq("07/29/16 11:22 AM")
        end

        it "should skip localization when explicitly specified as false" do
          expect(helper.pretty_date(@basis_utc, localize: false, style: :full)).to eq("07/29/16  4:22 PM")
        end
      end

      context "with undefined time zone" do
        before do
          allow(@current_user).to receive(:time_zone).and_return ""
        end

        it "should return unlocalized time" do
          expect(helper.pretty_date(@basis_utc, style: :full)).to eq("07/29/16  4:22 PM")
        end
      end
    end

    context "without current_user" do
      it "should ignore localization without any special options" do
        expect(helper.pretty_date(@basis_utc, style: :full)).to eq("07/29/16  4:22 PM")
      end

      it "should ignore localization flag if erroneously specified" do
        expect(helper.pretty_date(@basis_utc, localize: true, style: :full)).to eq("07/29/16  4:22 PM")
      end
    end
  end
end
