class NotificationFormatter
  def self.call(alert, price)
    "ALERT: #{alert.symbol} #{alert.direction} threshold=#{alert.threshold.to_i}, current=#{price}"
  end

  def self.payload(alert, price)
    {
      "symbol"    => alert.symbol,
      "price"     => price.to_s,
      "message"   => call(alert, price),
      "timestamp" => Time.current.iso8601
    }
  end
end
