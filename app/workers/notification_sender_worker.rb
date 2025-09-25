# class NotificationSenderWorker
#   include Sidekiq::Worker
#   sidekiq_options queue: :notifications, retry: 3
#
#   def perform(channel_kind, payload)
#     channel = channel_kind.to_s
#     DispatcherNotification.dispatch(payload, channels: [channel])
#   rescue => e
#     Rails.logger.error("NotificationSenderWorker failed: #{e.class} #{e.message}")
#     raise e
#   end
# end

class NotificationSenderWorker
  include Sidekiq::Worker
  sidekiq_options queue: :notifications, retry: 3

  def perform(channel_kind, alert_hash)
    DispatcherNotification.dispatch(alert_hash, channels: [channel_kind])
  rescue => e
    Rails.logger.error("NotificationSenderWorker failed: #{e.class} #{e.message}")
    raise e
  end
end