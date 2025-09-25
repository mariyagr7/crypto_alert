require "sidekiq"
require "sidekiq-cron"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Loading cron tasks from YAML
  schedule_file = Rails.root.join("config", "sidekiq-cron.yml")

  if File.exist?(schedule_file)
    schedule = YAML.load_file(schedule_file)
    Sidekiq::Cron::Job.load_from_hash(schedule)
    Rails.logger.info("[SidekiqCron] Loaded schedule from sidekiq-cron.yml")
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

# Optional: error logging
# Sidekiq::Logging.logger.level = Logger::INFO
