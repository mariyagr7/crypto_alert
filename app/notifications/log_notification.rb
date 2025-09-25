class LogNotification < BaseNotification
  def notify(message, meta: {})
    Rails.logger.info("[LOG] #{message}")
  end
end
