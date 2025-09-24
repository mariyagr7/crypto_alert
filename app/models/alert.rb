class Alert < ApplicationRecord
  DIRECTIONS = %w[up down].freeze
  CHANNELS = %w[log email telegram].freeze

  belongs_to :user, optional: true
  validates :symbol, presence: true
  validates :threshold, presence: true, numericality: { greater_than: 0 }
  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :check_interval_seconds, numericality: { greater_than_or_equal_to: 30 }
  validates :cooldown_seconds, numericality: { greater_than_or_equal_to: 60 }
  validate :channels_should_be_valid

  before_validation :upcase_symbol

  scope :active, -> { where(active: true) }
  scope :for_symbol, ->(s) { where(symbol: s.upcase) }
  scope :due, -> {
    where(active: true)
      .where("next_check_at IS NULL OR next_check_at <= ?", Time.current)
  }


  private

  def channels_should_be_valid
    return if channels.blank?

    unless channels.is_a?(Array)
      errors.add(:channels, "should be an array")
      return
    end

    invalid = channels - CHANNELS
    if invalid.any?
      errors.add(:channels, "includes unsupported values: #{invalid.join(', ')}")
    end
  end

  def upcase_symbol
    symbol.upcase! if symbol
  end
end
# Alert.create!(symbol: "BTCUSDT", threshold: 65000, direction: :up, check_interval_seconds: 30, next_check_at: Time.current)