require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe DocumentWorker, type: :worker do

  describe "Sidekiq Worker" do
    it "should respond to #perform" do
      expect(DocumentWorker.new).to respond_to(:perform)
    end

    describe "Handling PDF" do
      it "should generate a PDF" 
    end

    describe "Handling CSV" do
        it "should generate a CSV" 
      end
  end
end
