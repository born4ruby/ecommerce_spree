module Spree
  class Promotion::Actions::CreateAdjustment < PromotionAction
    calculated_adjustments

    delegate :eligible?, :to => :promotion

    before_validation :ensure_action_has_calculator

    def perform(options = {})
      return unless order = options[:order]
      # Nothing to do if the promotion is already associated with the order
      return if order.promotion_credit_exists?(promotion)

      order.adjustments.promotion.reload.clear
      order.update!
      create_adjustment("#{I18n.t(:promotion)} (#{promotion.name})", order, order)
    end

    # override of CalculatedAdjustments#create_adjustment so promotional
    # adjustments are added all the time. They will get their eligability
    # set to false if the amount is 0
    def create_adjustment(label, target, calculable, mandatory=false)
      amount = compute_amount(calculable)
      target.adjustments.create(:amount => amount,
                                :source => calculable,
                                :originator => self,
                                :label => label,
                                :mandatory => mandatory)
    end

    # Ensure a negative amount which does not exceed the sum of the order's item_total and ship_total
    def compute_amount(calculable)
      [(calculable.item_total + calculable.ship_total), super.to_f.abs].min * -1
    end

    private
    def ensure_action_has_calculator
      return if self.calculator
      self.calculator = Calculator::FlatPercentItemTotal.new
    end
  end
end
