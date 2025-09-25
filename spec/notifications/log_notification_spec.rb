require "rails_helper"
require "sidekiq/testing"

RSpec.describe LogNotification do
  let(:payload) do
    {
      "message" => "Test log message"
    }
  end

  it "logs the message with [LOG] prefix" do
    expect(Rails.logger).to receive(:info).with("[LOG] #{payload["message"]}")
    described_class.new.notify(payload)
  end
end
