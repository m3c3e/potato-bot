RSpec.describe Potato::Bot::Client::TypedResponse do
  let(:bot) { Potato::Bot::Client.new('token').tap { |x| x.extend described_class } }

  describe '#get_me' do
    subject { bot.get_me }
    before { expect(bot).to receive(:request).with(:getMe) { response } }
    let(:response) { {'ok' => true, 'result' => {'id' => user_id}} }
    let(:user_id) { 123 }
    it { should be_instance_of Potato::Bot::Types::User }
    its(:id) { should eq user_id }

    context 'on error' do
      let(:response) { raise Potato::Bot::Error }
      it { expect { subject }.to raise_error Potato::Bot::Error }
    end
  end

  describe '#get_updates' do
    subject { bot.get_updates }
    before { expect(bot).to receive(:request).with(:getUpdates) { response } }
    let(:response) { {'ok' => true, 'result' => [{'update_id' => update_id}]} }
    let(:update_id) { 123 }
    it { should be_instance_of Array }
    its(:first) { should be_instance_of Potato::Bot::Types::Update }
    its('first.update_id') { should eq update_id }

    context 'on error' do
      let(:response) { raise Potato::Bot::Error }
      it { expect { subject }.to raise_error Potato::Bot::Error }
    end
  end
end
