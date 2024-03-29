require 'spec_helper'

# Model and Controller concerns live under support because it's on the include path.
# Note this file name doesn't end in "_spec.rb" so that Rspec won't load it by default - otherwise it loads twice

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

  context "initialization" do
    before do
      allow_any_instance_of(SharedQueries).to receive(:param_context).with(:search_term).and_return('string with "quoted term" and     spaces embedded and trailing ')
      @query = init_query(Conference)
    end

    it "parses embedded strings as a single term" do
      expect(@query.terms.include?("quoted term")).to be_truthy
    end

    it "strips embedded spaces from the terms - no nil terms" do
      @query.terms.each do |term|
        expect(term.strip).to eq(term)
      end
    end
  end

  describe "query building" do
    before do
      @query = init_query(Conference)
    end

    context "with query terms defined in simple order" do
      before do
        @query.add SharedQueries::REQUIRED, "value is one", 1
        @query.add SharedQueries::REQUIRED, "value is two", 2
        @query.add SharedQueries::REQUIRED, "value is three", 3
        @query.add SharedQueries::OPTIONAL, "value is four", 4
        @query.add SharedQueries::OPTIONAL, "value is five", 5
        @query.add SharedQueries::ADDATIVE, "value is six", 6
        @query.add SharedQueries::ADDATIVE, "value is seven", 7
      end

      it "builds where clause and bindings in the right order" do
        expect(@query.where_clause).to eq("value is one AND value is two AND value is three AND (value is four OR value is five) OR value is six OR value is seven")
        expect(@query.bindings).to eq([1, 2, 3, 4, 5, 6, 7])
      end

      it "joins the major clauses correctly" do
        expect(@query.where_clause.include?("AND (value")).to be_truthy
        expect(@query.where_clause.include?(") OR value")).to be_truthy
      end
    end

    context "with query terms defined in adverse order" do
      before do
        @query.add SharedQueries::ADDATIVE, "value is seven", 7
        @query.add SharedQueries::OPTIONAL, "value is five", 5
        @query.add SharedQueries::REQUIRED, "value is two", 2
        @query.add SharedQueries::OPTIONAL, "value is four", 4
        @query.add SharedQueries::ADDATIVE, "value is six", 6
        @query.add SharedQueries::REQUIRED, "value is one", 1
        @query.add SharedQueries::REQUIRED, "value is three", 3
      end

      it "builds where clause and bindings with variables/bindings aligned and variables in the right group" do
        #                                 [------------------ required -------------------]     [----------- optional ---------]    [--------- addative ---------]
        expect(@query.where_clause).to eq("value is two AND value is one AND value is three AND (value is five OR value is four) OR value is seven OR value is six")
        expect(@query.bindings).to eq([2, 1, 3, 5, 4, 7, 6])
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
