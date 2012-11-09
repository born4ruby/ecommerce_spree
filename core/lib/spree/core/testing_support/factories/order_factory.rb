FactoryGirl.define do
  factory :order, :class => Spree::Order do
    # associations:
    association(:user, :factory => :user)
    association(:bill_address, :factory => :address)
    completed_at nil
    bill_address_id nil
    ship_address_id nil
    email 'foo@example.com'
  end

  factory :order_with_totals, :parent => :order do
    after_create { |order| Factory(:line_item, :order => order) }
  end

  factory :order_with_inventory_unit_shipped, :parent => :order do
    after_create do |order|
      Factory(:line_item, :order => order)
      Factory(:inventory_unit, :order => order, :state => 'shipped')
    end
  end
end
