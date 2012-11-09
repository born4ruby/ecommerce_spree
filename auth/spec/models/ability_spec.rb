require 'spec_helper'
require 'bar_ability'
require 'cancan/matchers'

# Fake ability for testing registration of additional abilities
class FooAbility
  include CanCan::Ability

  def initialize(user)
    # allow anyone to perform index on Order
    can :index, Spree::Order
    # allow anyone to update an Order with id of 1
    can :update, Spree::Order do |order|
      order.id == 1
    end
  end
end

describe Spree::Ability do
  let(:user) { Spree::User.new }
  let(:ability) { Spree::Ability.new(user) }
  let(:token) { nil }

  TOKEN = 'token123'

  after(:each) {
    Spree::Ability.abilities = Set.new
    user.roles = []
  }

  context 'register_ability' do
    it 'should add the ability to the list of abilties' do
      Spree::Ability.register_ability(FooAbility)
      Spree::Ability.new(user).abilities.should_not be_empty
    end

    it 'should apply the registered abilities permissions' do
      Spree::Ability.register_ability(FooAbility)
      Spree::Ability.new(user).can?(:update, mock_model(Spree::Order, :id => 1)).should be_true
    end
  end

  shared_examples_for 'access granted' do
    it 'should allow read' do
      ability.should be_able_to(:read, resource, token) if token
      ability.should be_able_to(:read, resource) unless token
    end

    it 'should allow create' do
      ability.should be_able_to(:create, resource, token) if token
      ability.should be_able_to(:create, resource) unless token
    end

    it 'should allow update' do
      ability.should be_able_to(:update, resource, token) if token
      ability.should be_able_to(:update, resource) unless token
    end
  end

  shared_examples_for 'access denied' do
    it 'should not allow read' do
      ability.should_not be_able_to(:read, resource)
    end

    it 'should not allow create' do
      ability.should_not be_able_to(:create, resource)
    end

    it 'should not allow update' do
      ability.should_not be_able_to(:update, resource)
    end
  end

  shared_examples_for 'index allowed' do
    it 'should allow index' do
      ability.should be_able_to(:index, resource)
    end
  end

  shared_examples_for 'no index allowed' do
    it 'should not allow index' do
      ability.should_not be_able_to(:index, resource)
    end
  end

  shared_examples_for 'create only' do
    it 'should allow create' do
      ability.should be_able_to(:create, resource)
    end

    it 'should not allow read' do
      ability.should_not be_able_to(:read, resource)
    end

    it 'should not allow update' do
      ability.should_not be_able_to(:update, resource)
    end

    it 'should not allow index' do
      ability.should_not be_able_to(:index, resource)
    end
  end

  shared_examples_for 'read only' do
    it 'should not allow create' do
      ability.should_not be_able_to(:create, resource)
    end

    it 'should allow read' do
      ability.should be_able_to(:read, resource)
    end

    it 'should not allow update' do
      ability.should_not be_able_to(:update, resource)
    end

    it 'should allow index' do
      ability.should be_able_to(:index, resource)
    end
  end

  context 'for general resource' do
    let(:resource) { Object.new }

    context 'with admin user' do
      before(:each) { user.stub(:has_role?).and_return(true) }
      it_should_behave_like 'access granted'
      it_should_behave_like 'index allowed'
    end

    context 'with customer' do
      it_should_behave_like 'access denied'
      it_should_behave_like 'no index allowed'
    end
  end

  context 'for admin protected resources' do
    let(:resource) { Object.new }
    let(:resource_shipment) { Spree::Shipment.new }
    let(:resource_product) { Spree::Product.new }
    let(:resource_user) { Spree::User.new }
    let(:resource_order) { Spree::Order.new }
    let(:fakedispatch_user) { Spree::User.new }
    let(:fakedispatch_ability) { Spree::Ability.new(fakedispatch_user) }

    context 'with admin user' do
      #before(:each) { user.stub(:has_role?).and_return(true) }
      it 'should be able to admin' do
        user.roles = [Spree::Role.find_or_create_by_name('admin')]
        ability.should be_able_to :admin, resource
        ability.should be_able_to :index, resource_order
        ability.should be_able_to :show, resource_product
        ability.should be_able_to :create, resource_user
      end
    end

    context 'with fakedispatch user' do
      it 'should be able to admin on the order and shipment pages' do
        user.roles = [Spree::Role.find_or_create_by_name('bar')]

        Spree::Ability.register_ability(BarAbility)

        ability.should_not be_able_to :admin, resource

        ability.should be_able_to :admin, resource_order
        ability.should be_able_to :index, resource_order
        ability.should_not be_able_to :update, resource_order
        # ability.should_not be_able_to :create, resource_order # Fails

        ability.should be_able_to :admin, resource_shipment
        ability.should be_able_to :index, resource_shipment
        ability.should be_able_to :create, resource_shipment

        ability.should_not be_able_to :admin, resource_product
        ability.should_not be_able_to :update, resource_product
        # ability.should_not be_able_to :show, resource_product # Fails

        ability.should_not be_able_to :admin, resource_user
        ability.should_not be_able_to :update, resource_user
        ability.should be_able_to :update, user
        # ability.should_not be_able_to :create, resource_user # Fails
        # It can create new users if is has access to the :admin, User!!

        # TODO change the Ability class so only users and customers get the extra premissions?
      end
    end

    context 'with customer' do
      it 'should not be able to admin' do
        ability.should_not be_able_to :admin, resource
        ability.should_not be_able_to :admin, resource_order
        ability.should_not be_able_to :admin, resource_product
        ability.should_not be_able_to :admin, resource_user
      end
    end
  end

  context 'for User' do
    context 'requested by same user' do
      let(:resource) { user }
      it_should_behave_like 'access granted'
      it_should_behave_like 'no index allowed'
    end
    context 'requested by other user' do
      let(:resource) { Spree::User.new }
      it_should_behave_like 'create only'
    end
  end

  context 'for Order' do
    let(:resource) { Spree::Order.new }

    context 'requested by same user' do
      before(:each) { resource.user = user }
      it_should_behave_like 'access granted'
      it_should_behave_like 'no index allowed'
    end

    context 'requested by other user' do
      before(:each) { resource.user = Spree::User.new }
      it_should_behave_like 'create only'
    end

    context 'requested with proper token' do
      let(:token) { 'TOKEN123' }
      before(:each) { resource.stub :token => 'TOKEN123' }
      it_should_behave_like 'access granted'
      it_should_behave_like 'no index allowed'
    end

    context 'requested with inproper token' do
      let(:token) { 'FAIL' }
      before(:each) { resource.stub :token => 'TOKEN123' }
      it_should_behave_like 'create only'
    end
  end

  context 'for Product' do
    let(:resource) { Spree::Product.new }
    context 'requested by any user' do
      it_should_behave_like 'read only'
    end
  end

  context 'for Taxons' do
    let(:resource) { Spree::Taxon.new }
    context 'requested by any user' do
      it_should_behave_like 'read only'
    end
  end
end
