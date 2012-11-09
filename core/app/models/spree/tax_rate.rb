module Spree
  class DefaultTaxZoneValidator < ActiveModel::Validator
    def validate(record)
      if record.included_in_price
        record.errors.add(:included_in_price, I18n.t(:included_price_validation)) unless Zone.default_tax
      end
    end
  end
end

module Spree
  class TaxRate < ActiveRecord::Base
    belongs_to :zone
    belongs_to :tax_category

    validates :amount, :presence => true, :numericality => true
    validates :tax_category_id, :presence => true
    validates_with DefaultTaxZoneValidator

    calculated_adjustments
    scope :by_zone, lambda { |zone| where(:zone_id => zone) }

    # Gets the array of TaxRates appropriate for the specified order
    def self.match(order)
      return [] unless order.tax_zone
      all.select do |rate|
        rate.zone == order.tax_zone || rate.zone.contains?(order.tax_zone) || rate.zone.default_tax
      end
    end

    # For Vat the default rate is the rate that is configured for the default category
    # It is needed for every price calculation (as all customer facing prices include vat )
    # The function returns the actual amount, which may be 0 in case of wrong setup, but is never nil
    def self.default
      category = TaxCategory.includes(:tax_rates).where(:is_default => true).first
      return 0 unless category

      address ||= Address.new(:country_id => Spree::Config[:default_country_id])
      rate = category.tax_rates.detect { |rate| rate.zone.include? address }.try(:amount)

      rate || 0
    end

    # Creates necessary tax adjustments for the order.
    def adjust(order)
      label = "#{tax_category.name} #{amount * 100}%"
      if self.included_in_price
        if Zone.default_tax.contains? order.tax_zone
          order.line_items.each { |line_item| create_adjustment(label, line_item, line_item) }
        else
          amount = -1 * calculator.compute(order)
          label = I18n.t(:refund) + label
          order.adjustments.create(:amount => amount,
                                   :source => order,
                                   :originator => self,
                                   :locked => true,
                                   :label => label)
        end
      else
        create_adjustment(label, order, order)
      end
    end

  end

end
