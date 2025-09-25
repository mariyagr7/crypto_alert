class AlertSchedulerWorker
  include Sidekiq::Worker

  def perform
    now = Time.current

    Alert.due.find_in_batches(batch_size: 500) do |batch|
      batch.each do |alert|
        AlertCheckerWorker.perform_async(alert.id)
        alert.update_column(:next_check_at, now + alert.check_interval_seconds.seconds)
      end
    end
  end
end
