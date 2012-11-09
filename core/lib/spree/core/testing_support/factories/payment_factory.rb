FactoryGirl.define do
  factory :payment, :class => Spree::Payment do
    amount 45.75
    payment_method { Factory(:bogus_payment_method) }
    source { Factory.build(:creditcard) }
    order { Factory(:order) }
    state 'pending'
    response_code '12345'

    # limit the payment amount to order's remaining balance, to avoid over-pay exceptions
    after_create do |pmt|
        #pmt.update_attribute(:amount, [pmt.amount, pmt.order.outstanding_balance].min)
    end
  end

  # factory :creditcard_txn do
  #   payment
  #   amount 45.75
  #   response_code 12345
  #   txn_type CreditcardTxn::TxnType::AUTHORIZE
  #
  #   # match the payment amount to the payment's value
  #   after_create do |txn|
  #     # txn.update_attribute(:amount, [txn.amount, txn.payment.payment].min)
  #     txn.update_attribute(:amount, txn.payment.amount)
  #   end
  # end
end
