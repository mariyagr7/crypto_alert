class NotificationDispatcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :notifications, retry: 5

  def perform(alert_id, price)
    alert = Alert.find_by(id: alert_id)
    return unless alert

    message = NotificationFormatter.call(alert, price)

    Array(alert.channels).each do |channel_kind|
      NotificationSenderWorker.perform_async(channel_kind, message)
    end
  rescue => e
    Rails.logger.error("NotificationDispatcherWorker failed for alert=#{alert_id}: #{e.class} #{e.message}")
    raise e
  end
end
