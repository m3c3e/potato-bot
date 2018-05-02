require 'potato/bot/routes_helper'

RSpec.describe Potato::Bot::RoutesHelper do
  let(:bot) { create_bot('bot_token') }
  let(:other_bot) { create_bot('other_token') }
  let(:bots) { {default: bot, other: other_bot} }

  def create_bot(*args)
    Potato::Bot::Client.new(*args)
  end

  describe '.route_name_for_bot' do
    subject { described_class.route_name_for_bot(input) }
    before { expect(Potato).to receive(:bots) { bots } }

    context 'when there is only one bot' do
      let(:bots) { {default: bot} }

      context 'for existing bot' do
        let(:input) { bot }
        it { should eq 'potato_webhook' }
      end

      context 'for non-existing bot' do
        let(:input) { other_bot }
        it { should eq 'potato_webhook' }
      end
    end

    context 'when there are multiple bots' do
      context 'for existing bot' do
        let(:input) { bot }
        it { should eq 'default_potato_webhook' }
      end

      context 'for non-existing bot' do
        let(:input) { double(:missing_bot) }
        it { should eq 'potato_webhook' }
      end
    end
  end

  describe '#potato_webhook' do
    subject { mapper.potato_webhook(*input) }
    let(:mapper) { double(:mapper).tap { |x| x.extend described_class } }
    let(:bots) { {default: bot, other: other_bot} }
    let(:controller) { double(:controller, name: :controller) }
    let(:other_controller) { double(:other_controller, name: :other_controller) }
    before { allow(Potato).to receive(:bots) { bots } }

    def assert_routes(bot, controller, route_name, options) # rubocop:disable AbcSize
      expected_path = options.delete(:path) || "potato/#{bot.token}"
      expect(mapper).to receive(:post) do |path, params|
        expect(path).to eq expected_path
        middleware = params[:to]
        expect(middleware.controller).to eq(controller)
        expect(middleware.bot.token).to eq(bot.token)
        expect(middleware.bot.username).to eq(bot.username)
        expect(params[:as]).to eq route_name
        expect(params).to include(options) if options
      end
      subject
    end

    context 'when called with controller' do
      let(:input) { [controller, option: :val] }

      it 'creates routes for default bot and this controller' do
        assert_routes bot, controller, 'default_potato_webhook', option: :val
      end

      context 'and bot does not have configured token' do
        let(:bot) { create_bot(nil) }
        it 'creates routes for default bot and this controller' do
          assert_routes bot, controller, 'default_potato_webhook', option: :val
        end
      end

      context 'and bot has colon in token' do
        let(:bot) { create_bot('some:token') }
        it 'replaces colon with underscore' do
          assert_routes bot, controller, 'default_potato_webhook',
            option: :val,
            path: 'potato/some_token'
        end
      end
    end

    context 'when called with controller and smth castable to bot' do
      let(:input) { [controller, 'custom_token', option: :val] }

      it 'creates routes for every created bot and controller' do
        assert_routes create_bot('custom_token'), controller, 'potato_webhook',
          option: :val
      end
    end
  end

  describe '#potato_webhooks' do
    subject { mapper.potato_webhooks(*input) }
    let(:mapper) { double(:mapper).tap { |x| x.extend described_class } }
    let(:bots) { {default: bot, other: other_bot} }
    let(:controller) { double(:controller, name: :controller) }
    let(:other_controller) { double(:other_controller, name: :other_controller) }
    before { allow(Potato).to receive(:bots) { bots } }
    around { |ex| Potato::Bot.deprecation_0_14.silence { ex.run } }

    def assert_routes(*expected) # rubocop:disable AbcSize
      expected.each do |(bot, controller, route_name, options)|
        expected_path = options.delete(:path) || "potato/#{bot.token}"
        expect(mapper).to receive(:post) do |path, params|
          expect(path).to eq expected_path
          middleware = params[:to]
          expect(middleware.controller).to eq(controller)
          expect(middleware.bot.token).to eq(bot.token)
          expect(middleware.bot.username).to eq(bot.username)
          expect(params[:as]).to eq route_name
          expect(params).to include(options) if options
        end
      end
      subject
    end

    context 'when called with controller' do
      let(:input) { [controller, option: :val] }

      it 'creates routes for every bot and this controller' do
        assert_routes [bot, controller, 'default_potato_webhook', option: :val],
                      [other_bot, controller, 'other_potato_webhook', option: :val]
      end

      context 'and bot does not have configured token' do
        let(:bot) { create_bot(nil) }
        it 'creates routes for every bot and this controller' do
          assert_routes [bot, controller, 'default_potato_webhook', option: :val],
                        [other_bot, controller, 'other_potato_webhook', option: :val]
        end
      end

      context 'and bot has colon in token' do
        let(:bot) { create_bot('some:token') }
        it 'replaces colon with underscore' do
          assert_routes [
            bot,
            controller,
            'default_potato_webhook',
            option: :val,
            path: 'potato/some_token',
          ], [other_bot, controller, 'other_potato_webhook', option: :val]
        end
      end
    end

    context 'when called with hash' do
      let(:input) do
        [
          {
            bot => controller,
            'custom_token' => [other_controller, as: :custom_route, option: :other_val],
            other: controller,
          },
          option: :val,
        ]
      end

      it 'creates routes for every bot and its controller' do
        assert_routes [bot, controller, 'default_potato_webhook', option: :val],
                      [
                        create_bot('custom_token'),
                        other_controller,
                        :custom_route,
                        option: :other_val,
                      ],
                      [Potato.bots[:other], controller, 'other_potato_webhook', option: :val]
      end
    end

    context 'when called with controller and smth castable to bot' do
      let(:input) do
        [
          controller,
          ['custom_token', token: bot.token, username: 'new_name'],
          option: :val,
        ]
      end

      it 'creates routes for every created bot and controller' do
        assert_routes [
          create_bot('custom_token'),
          controller,
          'potato_webhook',
          option: :val,
        ], [
          create_bot(bot.token, 'new_name'),
          controller,
          'potato_webhook',
          option: :val,
        ]
      end
    end
  end
end
