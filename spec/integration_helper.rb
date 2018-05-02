require 'potato/bot/rspec/integration'
require 'action_controller'
require 'action_dispatch'
require 'action_dispatch/testing/integration'

require 'rails'
require 'potato/bot/railtie'
require 'rspec/rails/adapters'
require 'rspec/rails/fixture_support'
require 'rspec/rails/example/rails_example_group'
require 'rspec/rails/example/request_example_group'

ENV['RAILS_ENV'] = 'test'
class TestApplication < Rails::Application
  config.eager_load = false
  config.log_level = :debug
  config.action_dispatch.show_exceptions = false

  potato_config = {
    bot: 'default_token',
    bots: {
      other: {token: 'other_token'},
      named: {token: 'named_token', username: 'TestBot'},
    },
  }

  if respond_to?(:credentials)
    credentials.config[:potato] = potato_config
  else
    secrets[:secret_key_base] = 'test'
    secrets[:potato] = potato_config
  end
end
Rails.application.initialize!

# # Controllers
%w[default other named].each do |bot_name|
  controller = Class.new(Potato::Bot::UpdatesController) do
    define_method :start do |*|
      respond_with :message, text: "from #{bot_name}"
    end
  end
  Object.const_set("#{bot_name}_bot_controller".camelize, controller)
end

[DefaultBotController, OtherBotController].each do |klass|
  klass.class_eval do
    use_session!

    define_method :load_session do |*|
      session[:test]
    end
  end
end

DefaultBotController.session_store = :memory_store

RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, type: :request

  config.around type: :request do |ex|
    begin
      Potato.reset_bots
      Potato::Bot::ClientStub.stub_all!
      ex.run
    ensure
      Potato.reset_bots
      Potato::Bot::ClientStub.stub_all!(false)
    end
  end

  config.before type: :request do
    # Redefine routes before every example, so it does not depent on order.
    Rails.application.routes.draw do
      require 'potato/bot/routes_helper'
      extend Potato::Bot::RoutesHelper

      potato_webhook DefaultBotController, :default
      potato_webhook OtherBotController, :other
      potato_webhook NamedBotController, :named
    end
  end
end
