require "rails_helper"
require "sidekiq/testing"

RSpec.describe NotificationFormatter do
  describe ".call" do
    let(:alert) do
      Alert.new(
        symbol: "BTCUSDT",
        direction: "up",
        threshold: 65000
      )
    end

    let(:price) { 67000 }

    it "returns formatted alert message" do
      expected_message = "ALERT: BTCUSDT up threshold=65000, current=67000"
      expect(NotificationFormatter.call(alert, price)).to eq(expected_message)
    end

    context "with down alert" do
      let(:alert) { Alert.new(symbol: "ETHUSDT", direction: "down", threshold: 2000) }
      let(:price) { 1900 }

      it "returns formatted message for down direction" do
        expected_message = "ALERT: ETHUSDT down threshold=2000, current=1900"
        expect(NotificationFormatter.call(alert, price)).to eq(expected_message)
      end
    end
  end
end
