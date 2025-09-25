require 'rails_helper'
require 'telegram/bot'
require 'sidekiq/testing'

RSpec.describe NotificationSenderWorker, type: :worker do
  let(:message) { "Test alert" }

  before do
    Sidekiq::Worker.clear_all
  end

  context "when channel is log" do
    it "dispatches the message to log channel" do
      expect(DispatcherNotification).to receive(:dispatch).with(message, channels: ["log"])
      described_class.new.perform("log", message)
    end
  end

  context "when channel is email" do
    it "dispatches the message to email channel" do
      expect(DispatcherNotification).to receive(:dispatch).with(message, channels: ["email"])
      described_class.new.perform("email", message)
    end
  end

  context "when channel is telegram" do
    before do
      stub_const("ENV", ENV.to_hash.merge("TG_BOT_TOKEN" => "token", "TG_CHAT_ID" => "123456"))
    end

    it "dispatches the message to telegram channel" do
      expect(DispatcherNotification).to receive(:dispatch).with(message, channels: ["telegram"])
      described_class.new.perform("telegram", message)
    end

    it "logs errors if dispatch raises an exception" do
      allow(DispatcherNotification).to receive(:dispatch).and_raise(StandardError.new("Telegram error"))
      expect(Rails.logger).to receive(:error).with(/NotificationSenderWorker failed: StandardError Telegram error/)
      expect { described_class.new.perform("telegram", message) }.to raise_error(StandardError, "Telegram error")
    end
  end

  context "when channel is unknown" do
    it "dispatches the message to unknown channel" do
      expect(DispatcherNotification).to receive(:dispatch).with(message, channels: ["unknown"])
      described_class.new.perform("unknown", message)
    end
  end
end
