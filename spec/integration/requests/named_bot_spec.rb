require 'integration_helper'

RSpec.describe NamedBotController, :potato_bot, type: :request do
  let(:bot) { Potato.bots[:named] }
  describe '#start' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message 'from named' }
  end
end
