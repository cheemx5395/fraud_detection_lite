class Transaction < ApplicationRecord
  belongs_to :user

  # Define constants for enums
  PAYMENT_MODES = %w[UPI CARD NETBANKING].freeze
  TRIGGER_FACTORS = %w[AMOUNT_DEVIATION FREQUENCY_SPIKE NEW_MODE TIME_ANOMALY].freeze
  DECISIONS = %w[ALLOW FLAG BLOCK].freeze

  # Validations
  validates :user_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :mode, presence: true, inclusion: { in: PAYMENT_MODES }
  validates :risk_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :decision, presence: true, inclusion: { in: DECISIONS }
  validates :amount_deviation_score, :frequency_deviation_score,
            :mode_deviation_score, :time_deviation_score,
            presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :validate_triggered_factors

  # Scopes
  scope :allowed, -> { where(decision: "ALLOW") }
  scope :flagged, -> { where(decision: "FLAG") }
  scope :blocked, -> { where(decision: "BLOCK") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  private

  def validate_triggered_factors
    return if triggered_factors.nil?

    invalid_factors = triggered_factors - TRIGGER_FACTORS
    if invalid_factors.any?
      errors.add(:triggered_factors, "contains invalid factors: #{invalid_factors.join(', ')}")
    end
  end
end
