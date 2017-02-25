FactoryGirl.define do
  factory :scale_type do
    name "Some scale"
    weight_unit "lb"
    region { (Region.all.count >= 5 ? Region.all.sort_by{ rand }.first : create(:region)) }
  end
end
