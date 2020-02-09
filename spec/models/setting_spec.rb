require 'rails_helper'

RSpec.describe Setting, type: :model do

  context "when getting settings for" do

    # Most of these don't do anything with the value, so it's not necessary to spec them
    describe "base event year" do
      it "gets the default" do
        expect(Setting.base_event_year).to eq(1959)
      end

      context "with a setting" do
        before do
          setting = Setting.first || Setting.create(base_event_year: 1958)
          setting.update base_event_year: 1952
        end

        it "gets the setting value not the default" do
          expect(Setting.base_event_year).to eq(1952)
        end
      end
    end
  end

end

