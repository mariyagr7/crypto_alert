require "rails_helper"
require "sidekiq/testing"

RSpec.describe AlertCheckerWorker, type: :worker do
  let(:symbol) { "BTCUSDT" }
  let(:threshold) { 65_000 }
  let!(:alert) do
    Alert.create!(
      symbol: symbol,
      direction: "up",
      threshold: threshold,
      cooldown_seconds: 300,
      channels: ["log", "email", "telegram"],
      active: true
    )
  end

  before do
    # Clear Redis keys for clean test
    Redis.current.del("price:#{symbol}")
  end

  describe "#perform" do
    context "when price in Redis triggers alert" do
      it "enqueues NotificationDispatcherWorker and updates last_triggered_at" do
        Redis.current.set("price:#{symbol}", "70000") # above threshold

        expect {
          described_class.new.perform(alert.id)
        }.to change(NotificationDispatcherWorker.jobs, :size).by(1)

        alert.reload
        expect(alert.last_triggered_at).to be_present
        expect(alert.last_triggered_price.to_f).to eq(70000)
      end
    end

    context "when price not in Redis but fetches successfully" do
      it "fetches price, caches it, triggers alert" do
        allow(PriceFetcher).to receive(:fetch).with(symbol).and_return(70000)

        expect {
          described_class.new.perform(alert.id)
        }.to change(NotificationDispatcherWorker.jobs, :size).by(1)

        expect(Redis.current.get("price:#{symbol}")).to eq("70000")
        alert.reload
        expect(alert.last_triggered_at).to be_present
      end
    end

    context "when price does not trigger alert" do
      it "does not enqueue notification or update last_triggered_at" do
        Redis.current.set("price:#{symbol}", "60000") # below threshold

        expect {
          described_class.new.perform(alert.id)
        }.not_to change(NotificationDispatcherWorker.jobs, :size)

        alert.reload
        expect(alert.last_triggered_at).to be_nil
      end
    end

    context "when cooldown is active" do
      it "does not trigger alert again" do
        alert.update!(last_triggered_at: Time.current) # cooldown active
        Redis.current.set("price:#{symbol}", "70000") # above threshold

        expect {
          described_class.new.perform(alert.id)
        }.not_to change(NotificationDispatcherWorker.jobs, :size)
      end
    end

    context "atomic update prevents double triggers" do
      it "only triggers if cooldown expired" do
        alert.update!(last_triggered_at: Time.current - 600) # cooldown expired
        Redis.current.set("price:#{symbol}", "70000")

        expect {
          described_class.new.perform(alert.id)
        }.to change(NotificationDispatcherWorker.jobs, :size).by(1)
      end
    end
  end
end
