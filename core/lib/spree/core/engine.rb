module Spree
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Spree
      engine_name 'spree'

      config.middleware.use "Spree::Core::Middleware::SeoAssist"
      config.middleware.use "Spree::Core::Middleware::RedirectLegacyProductUrl"

      config.autoload_paths += %W(#{config.root}/lib)

      def self.activate
      end

      config.to_prepare &method(:activate).to_proc

      config.after_initialize do
        ActiveSupport::Notifications.subscribe(/^spree\./) do |*args|
          event_name, start_time, end_time, id, payload = args
          Activator.active.event_name_starts_with(event_name).each do |activator|
            payload[:event_name] = event_name
            activator.activate(payload)
          end
        end

      end

      # We need to reload the routes here due to how Spree sets them up
      # The different facets of Spree, (auth, promo, etc.) appends/prepends routes to Core
      # *after* Core has been loaded.
      #
      # So we wait until after initialization is complete to do one final reload
      # This then makes the appended/prepended routes available to the application.
      config.after_initialize do
        Rails.application.routes_reloader.reload!
      end


      initializer "spree.environment", :before => :load_config_initializers do |app|
        app.config.spree = Spree::Core::Environment.new
        Spree::Config = app.config.spree.preferences #legacy access
      end

      initializer "spree.load_preferences", :before => "spree.environment" do
        ::ActiveRecord::Base.send :include, Spree::Preferences::Preferable
      end

      initializer "spree.register.calculators" do |app|
        app.config.spree.calculators.shipping_methods = [
            Spree::Calculator::FlatPercentItemTotal,
            Spree::Calculator::FlatRate,
            Spree::Calculator::FlexiRate,
            Spree::Calculator::PerItem,
            Spree::Calculator::PriceBucket]

         app.config.spree.calculators.tax_rates = [
            Spree::Calculator::DefaultTax]
      end

      initializer "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods = [
            Spree::Gateway::Bogus,
            Spree::Gateway::BogusSimple,
            Spree::PaymentMethod::Check ]
      end

      # filter sensitive information during logging
      initializer "spree.params.filter" do |app|
        app.config.filter_parameters += [:password, :password_confirmation, :number]
      end

      # sets the manifests / assets to be precompiled
      initializer "spree.assets.precompile" do |app|
        app.config.assets.precompile += ['store/all.*', 'admin/all.*', 'admin/orders/edit_form.js', 'jqPlot/excanvas.min.js', 'admin/images/new.js', 'jquery.jstree/themes/apple/*']
      end

      initializer "spree.asset.pipeline" do |app|
        app.config.assets.debug = false
      end

      initializer "spree.mail.settings" do |app|
        if Spree::MailMethod.table_exists?
          Spree::Core::MailSettings.init
          Mail.register_interceptor(Spree::Core::MailInterceptor)
        end
      end
    end
  end
end
