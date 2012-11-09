require 'spec_helper'

describe "Payments" do
  before(:each) do
    reset_spree_preferences do |config|
      config.allow_backorders = true
    end
  end

  context "payment methods" do
    before(:each) do
      Spree::Zone.delete_all
      ship_method = Factory(:shipping_method, :zone => Factory(:zone, :name => 'North America'))
      order = Factory(:order, :completed_at => "2011-02-01 12:36:15", :number => "R100", :ship_address => Factory(:address), :shipping_method => ship_method)
      product = Factory(:product, :name => 'spree t-shirt', :on_hand => 5)
      product.master.count_on_hand = 5
      product.master.save
      order.add_variant(product.master, 2)
      order.update!
      order.inventory_units.each do |iu|
        iu.update_attribute_without_callbacks('state', 'sold')
      end
      order.update!
      Factory(:payment, :order => order, :amount => order.outstanding_balance, :payment_method => Factory(:bogus_payment_method, :environment => 'test'))
      @order = order
    end

    it "should be able to list, edit, and create payment methods for an order", :js => true do
      pending "need to correctly associate inventory_units with order"

      visit spree.admin_path
      click_link "Orders"
      within('table#listing_orders tbody tr:nth-child(1)') { click_link "R100" }
      click_link "Payments"
      within('#payment_status') { page.should have_content("Payment: balance due") }
      find('table.index tbody tr:nth-child(2) td:nth-child(2)').text.should == "$39.98"
      find('table.index tbody tr:nth-child(2) td:nth-child(3)').text.should == "Credit Card"
      find('table.index tbody tr:nth-child(2) td:nth-child(4)').text.should == "pending"

      click_button "Void"
      within('#payment_status') { page.should have_content("Payment: balance due") }
      page.should have_content("Payment Updated")
      find('table.index tbody tr:nth-child(2) td:nth-child(2)').text.should == "$39.98"
      find('table.index tbody tr:nth-child(2) td:nth-child(3)').text.should == "Credit Card"
      find('table.index tbody tr:nth-child(2) td:nth-child(4)').text.should == "void"

      click_on "New Payment"
      page.should have_content("New Payment")
      click_button "Continue"
      click_button "Capture"
      within('#payment_status') { page.should have_content("Payment: paid") }
      page.should_not have_css('#new_payment_section')

      click_link "Shipments"
      click_on "New Shipment"
      #within('table.index tbody tr:nth-child(2)') { check "#inventory_unit" }
      save_and_open_page
      click_button "Create"
      page.should have_content("successfully created!")
    end
  end
end
