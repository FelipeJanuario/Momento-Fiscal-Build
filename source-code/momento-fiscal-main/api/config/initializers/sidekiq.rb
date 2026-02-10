# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV.fetch('REDIS_HOST', 'redis')}:#{ENV.fetch('REDIS_PORT', '6379')}/0" }
  schedule_file = 'config/schedule.yml'

  Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file)) if File.exist?(schedule_file)
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV.fetch('REDIS_HOST', 'redis')}:#{ENV.fetch('REDIS_PORT', '6379')}/0" }
end
