class AlertCheckerWorker
  include Sidekiq::Worker

  def perform(alert_id)
    alert = Alert.find_by(id: alert_id, active: true)
    return unless alert

    price = redis_price(alert.symbol) || fetch_and_cache_price(alert.symbol)
    return unless price

    price = BigDecimal(price.to_s)

    if should_trigger?(alert, price)
      if mark_triggered!(alert, price)
        NotificationDispatcherWorker.perform_async(alert.id, price.to_s)
      end
    end

    alert.update_column(:next_check_at, Time.current)
  end

  private

  def redis_price(symbol)
    Redis.current.get("price:#{symbol}")
  end

  def fetch_and_cache_price(symbol)
    fetched = PriceFetcher.fetch(symbol)
    if fetched
      Redis.current.setex("price:#{symbol}", 60, fetched.to_s)
    end
    fetched
  end

  def should_trigger?(alert, price)
    return false if alert.last_triggered_at &&
                    alert.last_triggered_at > Time.current - alert.cooldown_seconds

    (alert.direction == "up"   && price >= alert.threshold) ||
      (alert.direction == "down" && price <= alert.threshold)
  end

  def mark_triggered!(alert, price)
    rows = Alert.where(id: alert.id)
                .where("last_triggered_at IS NULL OR last_triggered_at <= ?", Time.current - alert.cooldown_seconds)
                .update_all(last_triggered_at: Time.current,
                            last_triggered_price: price.to_s)
    rows > 0
  end
end
