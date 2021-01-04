require 'rails_helper'

RSpec.describe Conference, type: :model do

  let(:organizer) { create :organizer }

  let(:valid_attributes) {
    {
      :event_type  => Conference::CONFERENCE,
      :organizer_id => organizer.id,
      :start_date   => '2005/07/15'.to_date,
      :end_date     => '2005/07/23'.to_date,
      :venue        => Conference::PHYSICAL
    }
  }

  it_behaves_like 'shared_queries'    # this only needs to be run once - so it's here

  describe "when creating a conference" do

    it "has a working factory" do
      expect(create :conference).to be_valid
    end

    it "is valid with valid attributes" do
      expect(Conference.new(valid_attributes)).to be_valid
    end

    context "validation" do
      [:organizer_id, :start_date, :end_date].each do |required_attribute|
        it "requires #{ required_attribute }" do
          expect(errors_on_blank(required_attribute)).to be_present
        end
      end
    end

    it "is invalid if start_date comes after end_date" do
      expect(Conference.new(valid_attributes.merge(end_date: '2005/07/01'.to_date))).not_to be_valid
    end

    it "uses the name from params, if one is provided" do
      conference = Conference.new(valid_attributes.merge(name: 'Provided Name'))
      conference.save!
      expect(conference.name).to eq('Provided Name')
    end

    context "when a name is not provided" do
      before do
        @conference = Conference.new(valid_attributes.merge(name: nil))
        @conference.save!
      end

      it "takes name from the organizer's series and the start date" do
        expect(@conference.name).to eq('OC 2005')
      end
    end

    context "when country is US" do
      it "is valid with a valid state" do
        expect(Conference.new(valid_attributes.merge(country: 'US', state: 'TX'))).to be_valid
      end

      it "is not case-sensitive on state" do
        expect(Conference.new(valid_attributes.merge(country: 'US', state: 'tx'))).to be_valid
      end

      it "is invalid with a non-existent state" do
        expect(Conference.new(valid_attributes.merge(country: 'US', city: 'Sometown', state: 'Typo'))).not_to be_valid
      end

      it "allows blank when the city is blank" do
        expect(Conference.new(valid_attributes.merge(country: 'US', city: '', state: ''))).to be_valid
      end
    end

    context "when country is not US" do
      it "state can be anything, including blank" do
        expect(Conference.new(valid_attributes.merge(country: 'Wombatistan', state: ''))).to be_valid
        expect(Conference.new(valid_attributes.merge(country: 'Wombatistan', state: 'Plutopia'))).to be_valid
      end
    end

    context "when venue is #{Conference::VIRTUAL}" do
      it "is valid without state" do
        expect(Conference.new(valid_attributes.merge(venue: Conference::VIRTUAL, state: ''))).to be_valid
      end
    end

    context "when venue is #{Conference::MULTIPLE}" do
      it "is valid without state" do
        expect(Conference.new(valid_attributes.merge(venue: Conference::MULTIPLE, state: ''))).to be_valid
      end
    end
  end

  describe "when updating a conference" do

    let(:conference) { Conference.create(valid_attributes) }

    it "uses the provided name in params" do
      conference.update(name: 'Updated Conference Name')
      expect(conference.name).to eq('Updated Conference Name')
    end

    context "changing the name" do
      context 'to a new string' do
        before do
          conference.update(name: 'New Conference Name')
        end

        it "generates a new slug" do
          expect(Conference.friendly.find('new-conference-name')).to eq(conference)
        end

        it "keeps the old slug history" do
          expect(Conference.friendly.find('oc-2005')).to eq(conference)
        end
      end

      context "to blank" do
        it "takes name from the organizer's series and the start date" do
          conference.update(name: '')
          expect(conference.name).to eq('OC 2005')
        end
      end
    end

    context "when changing the organizer" do

      let(:new_organizer) { create :organizer, name: "NewOrg", series_name: "New Conferences", abbreviation: "NewC"}

      context "with a default conference name" do
        before do
          expect(conference.name).to eq("OC 2005") # from default
          conference.update(organizer_id: new_organizer.id)
        end

        it "automatically updates the name to the new default indicated by the new organizer" do
          expect(conference.name).to eq("NewC 2005")
        end
      end

      context "with a manually modified conference name" do
        before do
          conference.update(name: "Special Event")
          conference.update(organizer_id: new_organizer.id)
        end

        it "leaves the conference name unchanged" do
          expect(conference.name).to eq("Special Event")
        end
      end
    end

    context "when changing the location type" do
      [Conference::VIRTUAL, Conference::MULTIPLE].each do |location_type|
        context "to #{ location_type }" do
          before { conference.update location_type: location_type }

          it "sets the city to #{location_type}" do
            expect(conference.city).to eq(location_type)
          end
        end
      end
    end

  end

  describe "when destroying a conference" do
    let(:conference) { create :conference }

    # Currently, conferences with presentations can't be destroyed - the presentations have to be
    # deleted or unlinked individually.
    # context "with presentations" do
    #   let!(:presentation) { create :presentation, conference_id: conference.id }
    #
    #   it "also destroys the presentations" do
    #     conference.destroy
    #     expect{ presentation.reload }.to raise_error ActiveRecord::RecordNotFound
    #   end
    # end

    context "with users" do
      let!(:user) { create :user }
      let!(:conference_user) { create :conference_user, conference_id: conference.id, user_id: user.id }

      it "also destroys the conference/user relationship" do
        conference.destroy
        expect{ conference_user.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not destroy the user" do
        conference.destroy
        expect(user.reload).to eq(user)
      end
    end

  end
end
