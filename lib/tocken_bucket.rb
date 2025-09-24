# lib/token_bucket.rb
class TokenBucket
  LUA_SCRIPT = <<~LUA
    local key       = KEYS[1]
    local capacity  = tonumber(ARGV[1])
    local refill    = tonumber(ARGV[2]) -- tokens per interval
    local interval  = tonumber(ARGV[3]) -- interval in seconds
    local now       = tonumber(ARGV[4])

    local bucket = redis.call("HMGET", key, "tokens", "timestamp")
    local tokens = tonumber(bucket[1])
    local last_ts = tonumber(bucket[2])

    if not tokens then
      tokens = capacity
      last_ts = now
    end

    -- refill
    local elapsed = now - last_ts
    local refill_tokens = math.floor(elapsed / interval * refill)
    if refill_tokens > 0 then
      tokens = math.min(capacity, tokens + refill_tokens)
      last_ts = now
    end

    local allowed = 0
    if tokens > 0 then
      tokens = tokens - 1
      allowed = 1
    end

    redis.call("HMSET", key, "tokens", tokens, "timestamp", last_ts)
    redis.call("EXPIRE", key, interval * 2)

    return allowed
  LUA

  def self.allow?(key, capacity: 5, refill: 5, per: 60.seconds)
    now = Time.now.to_i
    allowed = Redis.current.eval(
      LUA_SCRIPT,
      keys: [key],
      argv: [capacity, refill, per.to_i, now]
    )
    allowed == 1
  end
end
