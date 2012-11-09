FactoryGirl.define do
  sequence(:product_sequence) { |n| "Product ##{n} - #{rand(9999)}" }

  factory :product, :class => Spree::Product do
    name { Factory.next :product_sequence }
    description { Faker::Lorem.paragraphs(rand(5)+1).join("\n") }

    # associations:
    tax_category { |r| Spree::TaxCategory.find(:first) || r.association(:tax_category) }
    shipping_category { |r| Spree::ShippingCategory.find(:first) || r.association(:shipping_category) }

    price 19.99
    cost_price 17.00
    sku 'ABC'
    available_on 1.year.ago
    deleted_at nil
  end

  factory :product_with_option_types, :parent => :product do
    after_create { |product| Factory(:product_option_type, :product => product) }
  end

  factory :custom_product, :class => Spree::Product do
    name "Custom Product"
    price "17.99"
    description { Faker::Lorem.paragraphs(rand(5)+1).join("\n") }

    # associations:
    tax_category { |r| Spree::TaxCategory.find(:first) || r.association(:tax_category) }
    shipping_category { |r| Spree::ShippingCategory.find(:first) || r.association(:shipping_category) }

    sku 'ABC'
    available_on 1.year.ago
    deleted_at nil

    association :taxons
  end
end
