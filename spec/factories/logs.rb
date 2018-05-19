# frozen_string_literal: true

FactoryGirl.define do
  factory :log do
    notes 'Log Notes Testing123'
    weight_unit 'lb'
    region { (Region.all.count >= 5 ? Region.all.sample : create(:region)) }
    self.when { Date.today + (rand > 0.5 ? -1 : 1)*rand(10) } # have to do self. since when is a reserved word in ruby
    donor { Location.donors.count >= 5 ? Location.donors.sample : create(:donor) }

    after(:create) do |d|
      rand(1..3).times{
        d.recipients << (Location.recipients.count >= 5 ? Location.recipients.sample : create(:recipient))
      }
      rand(1..3).times{
        d.log_parts << create(:log_part)
      }
      d.scale_type = (ScaleType.all.count >= 5 ? ScaleType.all.sample : create(:scale_type, region: d.region))
      d.transport_type = (TransportType.all.count >= 5 ? TransportType.all.sample : create(:transport_type))
      d.save
    end

    # factory :log_from_chain do
    #  after(:create) do |d|
    #    schedule_chain { (ScheduleChain.all.count >= 5 ? ScheduleChain.all.sort_by{ rand }.first : create(:schedule_chain,region:d.region)) }
    #  end
    # end
  end
end
