require 'spec_helper'

describe "Checkout" do
  context "visitor makes checkout as guest without registration" do
    before do
      @product = Factory(:product, :name => "RoR Mug")
      Factory(:zone)
      Factory(:shipping_method)
      Factory(:payment_method)
      Factory(:promotion)
    end

    it "informs about an invalid coupon code", :js => true do
      visit spree.root_path
      click_link "RoR Mug"
      click_button "add-to-cart-button"

      click_link "Checkout"
      fill_in "order_email", :with => "spree@example.com"
      click_button "Continue"

      fill_in "First Name", :with => "John"
      fill_in "Last Name", :with => "Smith"
      fill_in "Street Address", :with => "1 John Street"
      fill_in "City", :with => "City of John"
      fill_in "Zip", :with => "01337"
      select "United States", :from => "Country"
      select "Alaska", :from => "order[bill_address_attributes][state_id]"
      fill_in "Phone", :with => "555-555-5555"
      check "Use Billing Address"

      # To shipping method screen
      click_button "Save and Continue"
      # To payment screen
      click_button "Save and Continue"

      fill_in "Coupon code", :with => "coupon_codes_rule_man"
      click_button "Save and Continue"
      page.should have_content("The coupon code you entered doesn't exist. Please try again.")
    end
  end
end


