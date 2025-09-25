require "rails_helper"
require "sidekiq/testing"

Sidekiq::Testing.inline!

RSpec.describe PriceFetcherWorker, type: :worker do
  let!(:alert1) { Alert.create!(symbol: "BTCUSDT", threshold: 65000, direction: "up", check_interval_seconds: 30, cooldown_seconds: 300) }
  let!(:alert2) { Alert.create!(symbol: "ETHUSDT", threshold: 4000, direction: "down", check_interval_seconds: 30, cooldown_seconds: 300) }

  before do
    Redis.current.flushdb
  end

  it "fetches prices for all distinct symbols and stores them in Redis" do
    prices = {
      "BTCUSDT" => 112_000.0,
      "ETHUSDT" => 4200.0
    }

    allow(PriceFetcher).to receive(:fetch_many).with(["BTCUSDT", "ETHUSDT"]).and_return(prices)

    described_class.new.perform

    expect(Redis.current.get("price:BTCUSDT")).to eq("112000.0")
    expect(Redis.current.get("price:ETHUSDT")).to eq("4200.0")
  end

  it "does nothing if fetch_many returns empty" do
    allow(PriceFetcher).to receive(:fetch_many).and_return({})

    described_class.new.perform

    expect(Redis.current.keys).to be_empty
  end

  it "calls fetch_many with unique symbols only" do
    Alert.create!(symbol: "BTCUSDT", threshold: 70000, direction: "up", check_interval_seconds: 30, cooldown_seconds: 300)

    expect(PriceFetcher).to receive(:fetch_many).with(["BTCUSDT", "ETHUSDT"]).and_return({})

    described_class.new.perform
  end
end
