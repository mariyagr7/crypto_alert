require "faraday"
require "json"

class PriceFetcher
  BASE_URL = "https://api.binance.com/api/v3/ticker/price"
  MAX_RETRIES = 3
  RATE_LIMIT = 10 # requests per second (Binance: ~1200/minute IP limit)

  class << self
    def fetch(symbol)
      with_rate_limit do
        with_retries do
          resp = connection.get(BASE_URL, { symbol: symbol })
          return JSON.parse(resp.body)["price"].to_f if resp.success?
          nil
        end
      end
    rescue => e
      Rails.logger.error("PriceFetcher.fetch(#{symbol}) failed: #{e.class} #{e.message}")
      nil
    end

    def fetch_many(symbols)
      with_rate_limit do
        with_retries do
          resp = connection.get(BASE_URL)
          return {} unless resp.success?

          data = JSON.parse(resp.body)
          data
            .select { |h| symbols.include?(h["symbol"]) }
            .to_h { |h| [ h["symbol"], h["price"].to_f ] }
        end
      end
    rescue => e
      Rails.logger.error("PriceFetcher.fetch_many failed: #{e.class} #{e.message}")
      {}
    end

    private

    def connection
      @connection ||= Faraday.new do |f|
        f.request :retry, max: 0 # we handle retries ourselves
        f.adapter Faraday.default_adapter
      end
    end

    def with_retries
      attempts = 0
      begin
        yield
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        attempts += 1
        if attempts <= MAX_RETRIES
          sleep(0.5 * attempts) # exponential backoff
          retry
        else
          Rails.logger.error("PriceFetcher retries exhausted: #{e.message}")
          raise
        end
      end
    end

    # simple in-process token bucket rate limiter
    def with_rate_limit
      @last_requests ||= []
      now = Time.now.to_f
      # drop old requests
      @last_requests.reject! { |t| t < now - 1 }
      if @last_requests.size >= RATE_LIMIT
        sleep_time = 1 - (now - @last_requests.first)
        sleep(sleep_time) if sleep_time > 0
      end
      @last_requests << Time.now.to_f
      yield
    end
  end
end
