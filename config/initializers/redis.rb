require "redis"

class Redis
  class << self
    attr_accessor :current
  end
end

Redis.current = Redis.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
)
