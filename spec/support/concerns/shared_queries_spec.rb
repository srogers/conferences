require 'spec_helper'

include SharedQueries

# This is a somewhat hacky way to get Rspec to allow param_context to be stubbed out directly on SharedQueries.
# Suppressess the error we'd otherwise get:  SharedQueries doesn't implement param_context
module SharedQueries
  def param_context
  end
end

# This is a somewhat hacky approach to testing SharedQueries directly, since it doesn't really get mixed into
# the caller. It only needs to be run in one place with:  it_behaves_like 'shared_queries'
shared_examples_for "shared_queries" do
  before do
    allow_any_instance_of(SharedQueries).to receive(:param_context).with(:search_term).and_return("foo")
    allow_any_instance_of(SharedQueries).to receive(:param_context).with(:tag).and_return("")
    allow_any_instance_of(SharedQueries).to receive(:param_context).with(:event_type).and_return("")
  end

  context "initializaton" do
    before do
      allow_any_instance_of(SharedQueries).to receive(:param_context).with(:search_term).and_return('string with "quoted term" and     embedded spaces')
      @query = init_query(Conference)
    end

    it "parses embedded strings as a single term" do
      expect(@query.terms.include?("quoted term")).to be_truthy
    end

    it "strips embedded spaces from the terms" do
      @query.terms.each do |term|
        expect(term.strip).to eq(term)
      end
    end
  end

  context "for events" do
    it "sets the query type" do
      query = init_query(Conference, false, false)
      expect(query.event?).to be_truthy
    end
  end

  context "for speakers" do
    it "sets the query type" do
      query = init_query(Speaker, false, false)
      expect(query.speaker?).to be_truthy
    end
  end
end
