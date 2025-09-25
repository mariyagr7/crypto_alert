# spec/workers/alert_scheduler_worker_spec.rb
require "rails_helper"
require "sidekiq/testing"

RSpec.describe AlertSchedulerWorker, type: :worker do
  include ActiveSupport::Testing::TimeHelpers

  let!(:due_alert1) do
    Alert.create!(
      symbol: "BTCUSDT",
      direction: "up",
      threshold: 65_000,
      check_interval_seconds: 30,
      cooldown_seconds: 300,
      channels: [ "log" ],
      next_check_at: 1.minute.ago,
      active: true
    )
  end

  let!(:due_alert2) do
    Alert.create!(
      symbol: "ETHUSDT",
      direction: "down",
      threshold: 3_000,
      check_interval_seconds: 60,
      cooldown_seconds: 300,
      channels: [ "email" ],
      next_check_at: 2.minutes.ago,
      active: true
    )
  end

  let!(:not_due_alert) do
    Alert.create!(
      symbol: "XRPUSDT",
      direction: "up",
      threshold: 1.2,
      check_interval_seconds: 30,
      cooldown_seconds: 300,
      channels: [ "telegram" ],
      next_check_at: 5.minutes.from_now,
      active: true
    )
  end

  describe "#perform" do
    it "enqueues AlertCheckerWorker for due alerts only" do
      expect {
        described_class.new.perform
      }.to change(AlertCheckerWorker.jobs, :size).by(2)
    end

    it "updates next_check_at for due alerts only" do
      now = Time.current
      travel_to now do
        described_class.new.perform
        due_alert1.reload
        due_alert2.reload
        not_due_alert.reload

        expect(due_alert1.next_check_at).to be_within(1.second).of(now + due_alert1.check_interval_seconds.seconds)
        expect(due_alert2.next_check_at).to be_within(1.second).of(now + due_alert2.check_interval_seconds.seconds)
        # unchanged for not due
        expect(not_due_alert.next_check_at).to be > now
      end
    end

    it "does not enqueue AlertCheckerWorker for alerts not due yet" do
      described_class.new.perform
      expect(AlertCheckerWorker.jobs.map { |j| j["args"].first }).not_to include(not_due_alert.id)
    end
  end
end
