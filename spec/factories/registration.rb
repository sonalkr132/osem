# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :registration do
    user
    conference { create(:conference, registration_period: create(:registration_period, start_date: 3.days.ago)) }
  end
end
