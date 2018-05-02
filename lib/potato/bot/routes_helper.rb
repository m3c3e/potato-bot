require 'potato/bot'
require 'active_support/core_ext/array/wrap'

module Potato
  module Bot
    module RoutesHelper
      class << self
        # Returns route name for given bot. Result depends on `Potato.bots`.
        # When there is single bot it returns 'potato_webhook'.
        # When there are it will use bot's key in the `Potato.bots` as prefix
        # (eg. `chat_potato_webhook`).
        def route_name_for_bot(bot)
          bots = Potato.bots
          if bots.size != 1
            name = bots.invert[bot]
            name && "#{name}_potato_webhook"
          end || 'potato_webhook'
        end

        # Replaces colon with underscore so rails don't treat it as
        # route parameter.
        def escape_token(token)
          token && token.tr(':', '_')
        end
      end

      #   # Create routes for all Potato.bots to use same controller:
      #   potato_webhooks PotatoController
      #
      #   # Or pass custom bots usin any of supported config options:
      #   potato_webhooks PotatoController, [
      #     bot,
      #     {token: token, username: username},
      #     other_bot_token,
      #   ]
      def potato_webhooks(controllers, bots = nil, **options)
        Bot.deprecation_0_14.deprecation_warning(:potato_webhooks, <<-TXT.strip_heredoc)
          It brings unnecessary complexity and encourages writeng less readable code.
          Please use potato_webhook method instead.
          It's signature `potato_webhook(controller, bot = :default, **options)`.
          Multiple-bot environments now requires calling this method in a loop
          or using statement for each bot.
        TXT
        unless controllers.is_a?(Hash)
          bots = bots ? Array.wrap(bots) : Potato.bots.values
          controllers = Hash[bots.map { |x| [x, controllers] }]
        end
        controllers.each do |bot, controller|
          controller, bot_options = controller if controller.is_a?(Array)
          potato_webhook(controller, bot, options.merge(bot_options || {}))
        end
      end

      # Define route which processes requests using given controller and bot.
      #
      #   potato_webhook PotatoController, bot
      #
      #   potato_webhook PotatoController
      #   # same as:
      #   potato_webhook PotatoController, :default
      #
      #   # pass additional options
      #   potato_webhook PotatoController, :default, as: :custom_route_name
      def potato_webhook(controller, bot = :default, **options)
        bot = Client.wrap(bot)
        params = {
          to: Middleware.new(bot, controller),
          as: RoutesHelper.route_name_for_bot(bot),
          format: false,
        }.merge!(options)
        post("potato/#{RoutesHelper.escape_token bot.token}", params)
        UpdatesPoller.add(bot, controller) if Potato.bot_poller_mode?
      end
    end
  end
end
