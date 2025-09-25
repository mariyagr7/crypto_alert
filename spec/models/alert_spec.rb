require "rails_helper"
require "sidekiq/testing"

RSpec.describe Alert, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      alert = Alert.new(
        symbol: "BTCUSDT",
        threshold: 65000,
        direction: "up",
        check_interval_seconds: 30,
        cooldown_seconds: 300,
        channels: ["log", "email"]
      )
      expect(alert).to be_valid
    end

    it "requires symbol" do
      alert = Alert.new(threshold: 100, direction: "up")
      expect(alert).not_to be_valid
      expect(alert.errors[:symbol]).to include("can't be blank")
    end

    it "requires threshold > 0" do
      alert = Alert.new(symbol: "BTCUSDT", threshold: 0, direction: "up")
      expect(alert).not_to be_valid
      expect(alert.errors[:threshold]).to include("must be greater than 0")
    end

    it "requires direction to be 'up' or 'down'" do
      alert = Alert.new(symbol: "BTCUSDT", threshold: 100, direction: "sideways")
      expect(alert).not_to be_valid
      expect(alert.errors[:direction]).to include("is not included in the list")
    end

    it "requires check_interval_seconds >= 30" do
      alert = Alert.new(symbol: "BTCUSDT", threshold: 100, direction: "up", check_interval_seconds: 10)
      expect(alert).not_to be_valid
      expect(alert.errors[:check_interval_seconds]).to include("must be greater than or equal to 30")
    end

    it "requires cooldown_seconds >= 60" do
      alert = Alert.new(symbol: "BTCUSDT", threshold: 100, direction: "up", cooldown_seconds: 10)
      expect(alert).not_to be_valid
      expect(alert.errors[:cooldown_seconds]).to include("must be greater than or equal to 60")
    end

    it "validates channels is an array" do
      alert = Alert.new(symbol: "BTCUSDT", direction: "up", threshold: 100, channels: ["sms"])
      expect(alert).not_to be_valid
      expect(alert.errors[:channels]).to include("includes unsupported values: sms")
    end

    it "validates channels includes only supported values" do
      alert = Alert.new(symbol: "BTCUSDT", threshold: 100, direction: "up", channels: ["log", "sms"])
      expect(alert).not_to be_valid
      expect(alert.errors[:channels]).to include("includes unsupported values: sms")
    end
  end

  describe "callbacks" do
    it "upcases symbol before validation" do
      alert = Alert.create!(
        symbol: "btcusdt",
        threshold: 65000,
        direction: "up",
        check_interval_seconds: 30,
        cooldown_seconds: 300
      )
      expect(alert.symbol).to eq("BTCUSDT")
    end
  end

  describe "scopes" do
    let!(:active_alert) { Alert.create!(symbol: "BTCUSDT", threshold: 65000, direction: "up", check_interval_seconds: 30, cooldown_seconds: 300, active: true) }
    let!(:inactive_alert) { Alert.create!(symbol: "ETHUSDT", threshold: 3000, direction: "down", check_interval_seconds: 30, cooldown_seconds: 300, active: false) }

    it "returns only active alerts" do
      expect(Alert.active).to include(active_alert)
      expect(Alert.active).not_to include(inactive_alert)
    end

    it "returns alerts for a given symbol" do
      expect(Alert.for_symbol("btcusdt")).to include(active_alert)
      expect(Alert.for_symbol("BTCUSDT")).to include(active_alert)
      expect(Alert.for_symbol("ETHUSDT")).not_to include(active_alert)
    end

    it "returns alerts due for checking" do
      due_alert = Alert.create!(symbol: "XRPUSDT", threshold: 1.2, direction: "up", check_interval_seconds: 30, cooldown_seconds: 300, active: true, next_check_at: 1.minute.ago)
      future_alert = Alert.create!(symbol: "ADAUSDT", threshold: 1.5, direction: "up", check_interval_seconds: 30, cooldown_seconds: 300, active: true, next_check_at: 5.minutes.from_now)

      expect(Alert.due).to include(due_alert)
      expect(Alert.due).not_to include(future_alert)
    end
  end
end
