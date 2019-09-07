require "rails_helper"

context "Legacy conference routes" do

  describe "index", :type => :request do
    it "redirects to /events" do
      expect(get("/conferences")).to redirect_to events_path
      expect(response).to be_moved_permanently
    end

    context "with params" do
      it "redirects to /events with params" do
        expect(get("/conferences?arbitrary=1&special=cheese")).to redirect_to events_path(arbitrary: '1', special: 'cheese')
        expect(response).to be_moved_permanently
      end

      it "doesn't get stuck on the same params" do
        expect(get("/conferences?arbitrary=2&wombats=3")).to redirect_to events_path(arbitrary: '2', wombats: '3')
        expect(response).to be_moved_permanently
      end
    end
  end

  describe "show", :type => :request do
    it "redirects to /events/slug" do
      expect(get("/conferences/my-conference-slug")).to redirect_to event_path('my-conference-slug')
      expect(response).to be_moved_permanently
    end
  end

  describe "upcoming", :type => :request do
    it "redirects to /events/upcoming" do
      expect(get("/conferences/upcoming")).to redirect_to upcoming_events_path
      expect(response).to be_moved_permanently
    end
  end

  describe "chart", :type => :request do
    it "redirects to /events/chart" do
      expect(get('/conferences/chart?type=cities')).to redirect_to chart_events_path(type: 'cities')
      expect(response).to be_moved_permanently
    end
  end

end
