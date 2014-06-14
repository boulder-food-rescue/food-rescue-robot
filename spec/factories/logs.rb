FactoryGirl.define do
  factory :log do
    notes "testing 123"
    weight_unit "lb"
    region { (Region.all.count >= 5 ? Region.all.sort_by{ rand }.first : create(:region)) }
    self.when { Date.today + (rand > 0.5 ? -1 : 1)*rand(10) } # have to do self. since when is a reserved word in ruby

    #after(:create) do |d|
    #  d.donor = (Location.donors.count >= 5 ? Location.donors.sort_by{ rand }.first : create(:donor))
    #  (0..rand(3)).times{
    #    d.recipients << (Location.recipients.count >= 5 ? Location.recipients.sort_by{ rand }.first : create(:recipient))
    #  }
    #  d.scale_type = (Location.donors.count >= 5 ? Location.donors.sort_by{ rand }.first : create(:scale_type,region:d.region))
    #end

    #factory :log_from_chain do
    #  after(:create) do |d|
    #    schedule_chain { (ScheduleChain.all.count >= 5 ? ScheduleChain.all.sort_by{ rand }.first : create(:schedule_chain,region:d.region)) }
    #  end
    #end

  end
end
