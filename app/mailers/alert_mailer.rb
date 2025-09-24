class AlertMailer < ApplicationMailer
  def price_alert(symbol:, price:, message:, timestamp:)
    @symbol = symbol
    @price = price
    @message = message
    @timestamp = timestamp

    mail(to: ENV["ALERT_EMAIL"], subject: "[ALERT] #{@symbol} price alert")
  end
end
