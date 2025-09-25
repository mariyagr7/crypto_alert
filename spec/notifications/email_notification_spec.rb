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

  it "enqueues an email delivery job with correct parameters" do
    ActiveJob::Base.queue_adapter = :test

    expect {
      described_class.new.notify(payload)
    }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with(
      "AlertMailer",
      "price_alert",
      "deliver_now",
      args: [ {
               symbol: payload["symbol"],
               price: payload["price"],
               message: payload["message"],
               timestamp: payload["timestamp"]
             } ]
    )
  end
end
