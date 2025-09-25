# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Alert.destroy_all
User.destroy_all

puts "Creating users..."
user1 = User.create!(
  email: "user1@example.com"
)

user2 = User.create!(
  email: "user2@example.com"
)

puts "Creating alerts for users..."

Alert.create!(
  user: user1,
  symbol: "BTCUSDT",
  direction: "up",
  threshold: 65000,
  check_interval_seconds: 30,
  cooldown_seconds: 300,
  channels: [ "log", "email", "telegram" ]
)

Alert.create!(
  user: user1,
  symbol: "ETHUSDT",
  direction: "down",
  threshold: 2000,
  check_interval_seconds: 60,
  cooldown_seconds: 600,
  channels: [ "log", "email" ]
)

Alert.create!(
  user: user2,
  symbol: "SOLUSDT",
  direction: "up",
  threshold: 30,
  check_interval_seconds: 45,
  cooldown_seconds: 300,
  channels: [ "log", "telegram" ]
)

puts "Seeding complete! Users and alerts created."
