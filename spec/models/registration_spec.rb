require 'spec_helper'

describe Registration do
  subject { create(:registration) }

  describe 'Validation' do

    it 'has a valid factory' do
      expect(build(:registration)).to be_valid
    end

    it { should validate_presence_of(:user) }

    it 'validates uniqueness of user in scope of conference' do
      expect(build(:registration, conference: subject.conference, user: subject.user)).not_to be_valid
    end

    describe 'registration_limit_not_exceed' do
      context 'registration_limit has exceeded' do
        before do
          registration = create(:registration)
          registration.conference.update_attributes(registration_limit: 1)
          @second_registration = build(:registration, conference: registration.conference)
        end

        it 'is not valid factory' do
          expect(@second_registration.valid?).to be false
          expect(@second_registration.errors.full_messages).to eq(['Registration limit exceeded'])
        end
      end
    end
  end

  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:conference) }
    it { should belong_to(:dietary_choice) }
    it { should have_and_belong_to_many(:social_events) }
    it { should have_and_belong_to_many(:events) }
    it { should have_and_belong_to_many(:qanswers) }
    it { should have_and_belong_to_many(:vchoices) }
    it { should have_many(:events_registrations) }
    it { should have_many(:workshops) }
  end

  describe 'callbacks' do
    after { subject.run_callbacks(:create) }

    it 'sets week of registration' do
      expect(subject).to receive(:set_week)
    end

    it 'subscribes to conference' do
      expect(subject).to receive(:subscribe_to_conference)
    end

    it 'sends registrations mail' do
      expect(subject).to receive(:send_registration_mail)
    end
  end

  describe 'methods' do
    describe '#week' do
      before { subject.created_at = Date.new(2014, 06, 30)}

      it 'returns week number of created_at' do
        expect(subject.week).to eq(26)
      end
    end
  end
end
