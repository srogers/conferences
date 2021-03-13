require 'spec_helper'

# Model and Controller concerns live under support because it's on the include path.
# Note this file name doesn't end in "_spec.rb" so that Rspec won't load it by default - otherwise it loads twice

shared_examples_for "sortable" do
  let(:controller) { described_class } # the class that includes the concern

  it "includes sortability" do
    expect(subject.ancestors.include? Sortability).to be(true) 
  end

  describe "with defaults", type: :controller do
    let(:object) { described_class.new }                              # we can use this to call methods in Sortability
        
    it "gets default sort" do
      object.class_eval { def params; {}; end}                        # this gets params defined for Sortability to operate on
      expect(object.params_to_sql("default")).to eq("default DESC")
    end
  end
end
