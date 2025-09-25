require "rails_helper"
require "sidekiq/testing"
require 'telegram/bot'

RSpec.describe TelegramNotification do
  let(:message) { "Hello TG" }
  let(:token)   { "fake-token" }
  let(:chat_id) { "123456" }

  subject(:notification) { described_class.new }

  before do
    ENV["TG_BOT_TOKEN"] = token
    ENV["TG_CHAT_ID"]   = chat_id
  end

  it "logs the message initially" do
    allow(Telegram::Bot::Client).to receive(:run)
    expect(Rails.logger).to receive(:info).with("[Telegram] #{message}")
    expect(Rails.logger).to receive(:info)
                              .with("TelegramNotification sent successfully to chat_id=#{chat_id}")
    notification.notify(message)
  end

  it "skips if token or chat_id missing" do
    ENV["TG_BOT_TOKEN"] = nil
    ENV["TG_CHAT_ID"]   = nil

    expect(Rails.logger).to receive(:warn)
                              .with("TelegramNotification skipped: missing TG_BOT_TOKEN or TG_CHAT_ID")

    notification.notify(message)
  end

  it "sends a message successfully" do
    bot_double = double("bot", api: double("api", send_message: true))

    expect(Telegram::Bot::Client).to receive(:run).with(token).and_yield(bot_double)
    expect(Rails.logger).to receive(:info).with("[Telegram] #{message}")
    expect(Rails.logger).to receive(:info).with("TelegramNotification sent successfully to chat_id=#{chat_id}")

    notification.notify(message)
  end

  it "logs error if Telegram API raises ResponseError" do
    fake_response = double(
      "response",
      body: "bad request",
      status: 400,
      env: double("env", url: "https://api.telegram.org")
    )

    expect(Telegram::Bot::Client).to receive(:run)
                                       .and_raise(Telegram::Bot::Exceptions::ResponseError.new(response: fake_response))

    expect(Rails.logger).to receive(:info).with("[Telegram] #{message}")
    expect(Rails.logger).to receive(:error) do |msg|
      expect(msg).to include("TelegramNotification failed (Telegram API)")
      expect(msg).to include("error_code: 400")
    end

    notification.notify(message)
  end


  it "logs unexpected error" do
    expect(Telegram::Bot::Client).to receive(:run).and_raise(StandardError.new("oops"))
    expect(Rails.logger).to receive(:info).with("[Telegram] #{message}")
    expect(Rails.logger).to receive(:error).with(/TelegramNotification failed \(unexpected\): StandardError oops/)

    notification.notify(message)
  end
end
