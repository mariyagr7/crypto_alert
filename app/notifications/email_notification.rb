class EmailNotification < BaseNotification
  def notify(payload)
    symbol    = payload["symbol"]
    price     = payload["price"]
    message   = payload["message"]
    timestamp = payload["timestamp"]

    AlertMailer.price_alert(
      symbol: symbol,
      price: price,
      message: message,
      timestamp: timestamp
    ).deliver_later
  rescue => e
    Rails.logger.error("EmailNotification failed: #{e.class} #{e.message}")
  end
end
