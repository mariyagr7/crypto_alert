require "rails_helper"
require "sidekiq/testing"

RSpec.describe DispatcherNotification do
  let(:message) { "Test message" }

  it "dispatches to log channel" do
    expect_any_instance_of(LogNotification).to receive(:notify).with(message)
    described_class.dispatch(message, channels: [:log])
  end

  it "dispatches to email channel" do
    expect_any_instance_of(EmailNotification).to receive(:notify).with(message)
    described_class.dispatch(message, channels: [:email])
  end

  it "dispatches to telegram channel" do
    expect_any_instance_of(TelegramNotification).to receive(:notify).with(message)
    described_class.dispatch(message, channels: [:telegram])
  end

  it "skips unknown channels" do
    expect { described_class.dispatch(message, channels: [:foo]) }.not_to raise_error
  end
end
