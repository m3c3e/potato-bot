require 'potato/bot/config_methods'

module Potato
  extend Bot::ConfigMethods

  module Bot
    class Error < StandardError; end

    # Raised for valid potato response with 403 status code.
    class Forbidden < Error; end

    # Raised for valid potato response with 404 status code.
    class NotFound < Error; end

    module_function

    def deprecation_0_14
      @deprecation ||= begin
        require 'active_support/deprecation'
        ActiveSupport::Deprecation.new('0.14', 'Potato::Bot')
      end
    end

    autoload :Async,              'potato/bot/async'
    autoload :Botan,              'potato/bot/botan'
    autoload :Client,             'potato/bot/client'
    autoload :ClientStub,         'potato/bot/client_stub'
    autoload :DebugClient,        'potato/bot/debug_client'
    autoload :Initializers,       'potato/bot/initializers'
    autoload :Middleware,         'potato/bot/middleware'
    autoload :RSpec,              'potato/bot/rspec'
    autoload :UpdatesController,  'potato/bot/updates_controller'
    autoload :UpdatesPoller,      'potato/bot/updates_poller'
  end
end

require 'potato/bot/railtie' if defined?(Rails)
