require "rails_helper"
require "sidekiq/testing"

require "rails_helper"
require "sidekiq/testing"

RSpec.describe NotificationDispatcherWorker, type: :worker do
  let!(:alert) do
    Alert.create!(
      symbol: "BTCUSDT",
      threshold: 65000,
      direction: "up",
      check_interval_seconds: 30,
      cooldown_seconds: 300,
      channels: ["log", "email", "telegram"]
    )
  end

  before do
    Sidekiq::Worker.clear_all
  end

  it "enqueues a NotificationSenderWorker for each channel" do
    payload_hash = {
      "message" => "ALERT MESSAGE",
      "price" => "112000.0",
      "symbol" => "BTCUSDT",
      "timestamp" => Time.current.iso8601
    }

    allow(NotificationFormatter).to receive(:payload).and_return(payload_hash)
    described_class.new.perform(alert.id, 112_000.0)
    expect(NotificationSenderWorker.jobs.size).to eq(3)

    channel_kinds = NotificationSenderWorker.jobs.map { |j| j["args"].first }
    expect(channel_kinds).to contain_exactly("log", "email", "telegram")
    messages = NotificationSenderWorker.jobs.map { |j| j["args"][1]["message"] }
    expect(messages).to all(eq("ALERT MESSAGE"))
  end

  it "does nothing if the alert does not exist" do
    expect {
      described_class.new.perform(0, 100.0)
    }.not_to change { NotificationSenderWorker.jobs.size }
  end

  it "logs and raises if an error occurs" do
    allow(Alert).to receive(:find_by).and_raise(StandardError.new("boom"))

    expect(Rails.logger).to receive(:error).with(/NotificationDispatcherWorker failed for alert=\d+: StandardError boom/)
    expect {
      described_class.new.perform(alert.id, 112_000.0)
    }.to raise_error(StandardError, "boom")
  end
end
