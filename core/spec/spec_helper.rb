# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'database_cleaner'
require 'spree/core/testing_support/factories'
require 'spree/core/testing_support/env'
require 'spree/url_helpers'


RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  #config.include Devise::TestHelpers, :type => :controller
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:each) do
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation, { :except => ['spree_countries', 'spree_zones', 'spree_zone_members', 'spree_states', 'spree_roles'] }
    else
      DatabaseCleaner.strategy = :transaction
    end
  end

  config.before(:each) do
    DatabaseCleaner.start
    reset_spree_preferences
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include Spree::UrlHelpers
end

shared_context "custom products" do
  before(:each) do
    reset_spree_preferences do |config|
      config.allow_backorders = true
    end

    taxonomy = Factory(:taxonomy, :name => 'Categories')
    root = taxonomy.root
    clothing_taxon = Factory(:taxon, :name => 'Clothing', :parent_id => root.id)
    bags_taxon = Factory(:taxon, :name => 'Bags', :parent_id => root.id)
    mugs_taxon = Factory(:taxon, :name => 'Mugs', :parent_id => root.id)

    taxonomy = Factory(:taxonomy, :name => 'Brands')
    root = taxonomy.root
    apache_taxon = Factory(:taxon, :name => 'Apache', :parent_id => root.id)
    rails_taxon = Factory(:taxon, :name => 'Ruby on Rails', :parent_id => root.id)
    ruby_taxon = Factory(:taxon, :name => 'Ruby', :parent_id => root.id)

    Factory(:custom_product, :name => 'Ruby on Rails Ringer T-Shirt', :price => '17.99', :taxons => [rails_taxon, clothing_taxon])
    Factory(:custom_product, :name => 'Ruby on Rails Mug', :price => '13.99', :taxons => [rails_taxon, mugs_taxon])
    Factory(:custom_product, :name => 'Ruby on Rails Tote', :price => '15.99', :taxons => [rails_taxon, bags_taxon])
    Factory(:custom_product, :name => 'Ruby on Rails Bag', :price => '22.99', :taxons => [rails_taxon, bags_taxon])
    Factory(:custom_product, :name => 'Ruby on Rails Baseball Jersey', :price => '19.99', :taxons => [rails_taxon, clothing_taxon])
    Factory(:custom_product, :name => 'Ruby on Rails Stein', :price => '16.99', :taxons => [rails_taxon, mugs_taxon])
    Factory(:custom_product, :name => 'Ruby on Rails Jr. Spaghetti', :price => '19.99', :taxons => [rails_taxon, clothing_taxon])
    Factory(:custom_product, :name => 'Ruby Baseball Jersey', :price => '19.99', :taxons => [ruby_taxon, clothing_taxon])
    Factory(:custom_product, :name => 'Apache Baseball Jersey', :price => '19.99', :taxons => [apache_taxon, clothing_taxon])
  end
end


PAYMENT_STATES = Spree::Payment.state_machine.states.keys unless defined? PAYMENT_STATES
SHIPMENT_STATES = Spree::Shipment.state_machine.states.keys unless defined? SHIPMENT_STATES
ORDER_STATES = Spree::Order.state_machine.states.keys unless defined? ORDER_STATES

# Usage:
#
# context "factory" do
#   it { should have_valid_factory(:address) }
# end
RSpec::Matchers.define :have_valid_factory do |factory_name|
  match do |model|
    Factory(factory_name).new_record?.should be_false
  end
end
