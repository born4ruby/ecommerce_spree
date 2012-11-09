FactoryGirl.define do
  factory :global_zone, :class => Spree::Zone do
    name 'GlobalZone'
    description { Faker::Lorem.sentence }
    zone_members do |proxy|
      zone = proxy.instance_eval{@instance}
      Spree::Country.find(:all).map{|c| Spree::ZoneMember.create({:zoneable => c, :zone => zone})}
    end
  end

  factory :zone, :class => Spree::Zone do
    name { Faker::Lorem.words }
    description { Faker::Lorem.sentence }
    zone_members { [Spree::ZoneMember.create(:zoneable => Factory(:country) )] }
  end
end
