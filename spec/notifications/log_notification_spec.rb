require "rails_helper"
require "sidekiq/testing"

RSpec.describe LogNotification do
  it "logs the notification" do
    expect(Rails.logger).to receive(:info).with("[LOG] hello")
    described_class.new.notify("hello")
  end
end
