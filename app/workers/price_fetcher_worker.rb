class PriceFetcherWorker
  include Sidekiq::Worker

  def perform
    symbols = Alert.distinct.pluck(:symbol)
    prices = PriceFetcher.fetch_many(symbols)

    prices.each do |symbol, price|
      Redis.current.setex("price:#{symbol}", 60, price)
    end
  end
end
