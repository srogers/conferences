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

    context "retaining params for navigation" do
      it "saves nav-related params in session"
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

  context "sharing bar" do
    before do
      @current_user = create :user, role: Role.reader, time_zone: "Central Time (US & Canada)"
      log_in @current_user
    end

    context" for event" do
      before do
        @conference = create :conference, name: 'The Title', description: 'superduper'
      end

      context "OG meta tags" do
        let(:doc) { helper.fb_social_bar; Nokogiri::HTML(helper.content_for :meta) }

        it "includes url" do
          expect(doc.css("meta[property='og:url']").first.attributes["content"].value).to eq(event_url @conference)
        end

        it "includes type" do
          # This seems right, because there are very few choices
          expect(doc.css("meta[property='og:type']").first.attributes["content"].value).to eq('article')
        end

        it "includes title" do
          expect(doc.css("meta[property='og:title']").first.attributes["content"].value).to eq(@conference.name)
        end

        context "description" do
          it "matches conference description" do
            expect(doc.css("meta[property='og:description']").first.attributes["content"].value).to eq(@conference.description)
          end

          context "with HTML" do
            before { @conference.description = '<div>here is <b>some</b> rich text</div>' }
            it "has tags stripped out" do
              expect(doc.css("meta[property='og:description']").first.attributes["content"].value).to eq('here is some rich text')
            end
          end
        end

        it "includes site name" do
          expect(doc.css("meta[property='og:site_name']").first.attributes["content"].value).to eq('Objectivist Conferences')
        end

        context "for image" do
          it "includes url" do
            expect(doc.css("meta[property='og:image']").first.attributes["content"].value).to include("assets/logo")
          end

          it "includes type" do
            expect(doc.css("meta[property='og:image:type']").first.attributes["content"].value).to eq("image/jpeg")
          end

          it "includes width" do
            expect(doc.css("meta[property='og:image:width']").first.attributes["content"].value).to eq('1200')
          end

          it "includes height" do
            expect(doc.css("meta[property='og:image:height']").first.attributes["content"].value).to eq('630')
          end
        end
      end
    end

    context" for presentation" do
      before do
        @presentation = create :presentation, name: 'The Title', description: 'superduper'
      end

      context "OG meta tags" do
        let(:doc) { helper.fb_social_bar; Nokogiri::HTML(helper.content_for :meta) }

        it "includes url" do
          expect(doc.css("meta[property='og:url']").first.attributes["content"].value).to eq(presentation_url @presentation)
        end

        it "includes type" do
          # This seems right, because there are very few choices
          expect(doc.css("meta[property='og:type']").first.attributes["content"].value).to eq('article')
        end

        it "includes title" do
          expect(doc.css("meta[property='og:title']").first.attributes["content"].value).to eq(@presentation.name)
        end

        it "includes description" do
          expect(doc.css("meta[property='og:description']").first.attributes["content"].value).to eq(@presentation.description)
        end

        it "includes site name" do
          expect(doc.css("meta[property='og:site_name']").first.attributes["content"].value).to eq('Objectivist Conferences')
        end

        context "for image" do
          it "includes url" do
            expect(doc.css("meta[property='og:image']").first.attributes["content"].value).to include("assets/logo")
          end

          it "includes type" do
            expect(doc.css("meta[property='og:image:type']").first.attributes["content"].value).to eq("image/jpeg")
          end

          it "includes width" do
            expect(doc.css("meta[property='og:image:width']").first.attributes["content"].value).to eq('1200')
          end

          it "includes height" do
            expect(doc.css("meta[property='og:image:height']").first.attributes["content"].value).to eq('630')
          end
        end
      end
    end

    context" for publication" do
      before do
        @publication = create :publication, name: 'The Title'
      end

      context "OG meta tags" do
        let(:doc) { helper.fb_social_bar; Nokogiri::HTML(helper.content_for :meta) }

        it "includes url" do
          expect(doc.css("meta[property='og:url']").first.attributes["content"].value).to eq(publication_url @publication)
        end

        it "includes type" do
          # This seems right, because there are very few choices
          expect(doc.css("meta[property='og:type']").first.attributes["content"].value).to eq('article')
        end

        it "includes title" do
          expect(doc.css("meta[property='og:title']").first.attributes["content"].value).to eq(@publication.name)
        end

        it "includes description" do
          expect(doc.css("meta[property='og:description']").first.attributes["content"].value).to eq(@publication.description)
        end

        it "includes site name" do
          expect(doc.css("meta[property='og:site_name']").first.attributes["content"].value).to eq('Objectivist Conferences')
        end

        context "for image" do
          it "includes url" do
            expect(doc.css("meta[property='og:image']").first.attributes["content"].value).to include("assets/logo")
          end

          it "includes type" do
            expect(doc.css("meta[property='og:image:type']").first.attributes["content"].value).to eq("image/jpeg")
          end

          it "includes width" do
            expect(doc.css("meta[property='og:image:width']").first.attributes["content"].value).to eq('1200')
          end

          it "includes height" do
            expect(doc.css("meta[property='og:image:height']").first.attributes["content"].value).to eq('630')
          end
        end
      end
    end
  end

end
