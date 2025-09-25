require "rails_helper"
require "sidekiq/testing"

RSpec.describe EmailNotification do
  let(:payload) do
    {
      "symbol"    => "BTCUSDT",
      "price"     => "70000.0",
      "message"   => "ALERT: BTCUSDT up threshold=65000, current=70000.0",
      "timestamp" => Time.current
    }
  end

  it "logs email with symbol, price and message" do
    expect(Rails.logger).to receive(:info)
                              .with("[EMAIL] #{payload["message"]} (#{payload["symbol"]}@#{payload["price"]})")

    mail_double = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(AlertMailer).to receive(:price_alert).and_return(mail_double)

    described_class.new.notify(payload)
  end
end
