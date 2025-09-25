class LogNotification < BaseNotification
  def notify(payalod)
    Rails.logger.info("[LOG] #{payalod["message"]}")
  end
end
