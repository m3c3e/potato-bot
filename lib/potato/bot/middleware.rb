require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/json'
require 'action_dispatch/http/mime_type'
require 'action_dispatch/http/request'

module Potato
  module Bot
    class Middleware
      attr_reader :bot, :controller

      def initialize(bot, controller)
        @bot = bot
        @controller = controller
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        #update = request.request_parameters
        Rails.logger.info("------------call")
        Rails.logger.info(request.raw_post)
        Rails.logger.info("------")
        response = JSON.parse(request.raw_post)
        Rails.logger.info(response.inspect)
        updates = response.is_a?(Array) ? response : response['result']
        updates.each do |update|
          controller.dispatch(bot, update)
        end
        [200, {}, ['']]
      end

      def inspect
        "#<#{self.class.name}(#{controller.try!(:name)})>"
      end
    end
  end
end
