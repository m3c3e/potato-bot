require 'potato/bot/routes_helper'

module Potato
  module Bot
    class Railtie < Rails::Railtie
      config.potato_updates_controller = ActiveSupport::OrderedOptions.new

      rake_tasks do
        load 'tasks/potato-bot.rake'
      end

      config.before_initialize do
        ::ActionDispatch::Routing::Mapper.send(:include, RoutesHelper)
      end

      initializer 'potato.bot.updates_controller.set_config' do |app|
        options = app.config.potato_updates_controller

        ActiveSupport.on_load('potato.bot.updates_controller') do
          self.logger = options.logger || Rails.logger
          self.session_store = options.session_store if options.session_store
        end
      end

      initializer 'potato.bot.updates_controller.add_ar_runtime' do
        ActiveSupport.on_load('potato.bot.updates_controller') do
          if defined?(ActiveRecord::Railties::ControllerRuntime)
            prepend ActiveRecord::Railties::ControllerRuntime
            extend ActiveRecord::Railties::ControllerRuntime::ClassMethods
          end
        end
      end
    end
  end
end
