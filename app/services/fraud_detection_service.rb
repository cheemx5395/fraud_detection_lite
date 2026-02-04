class FraudDetectionService
  # Risk score thresholds
  ALLOW_THRESHOLD = 50
  FLAG_THRESHOLD = 75

  # Score weights (must total 100)
  AMOUNT_WEIGHT = 40
  FREQUENCY_WEIGHT = 30
  MODE_WEIGHT = 20
  TIME_WEIGHT = 10

  def self.analyze(user:, profile:, amount:, mode:)
    new(user, profile, amount, mode).analyze
  end

  def initialize(user, profile, amount, mode)
    @user = user
    @profile = profile
    @amount = amount
    @mode = mode
    @triggered_factors = []
  end

  def analyze
    # Calculate individual scores (0-100 scale)
    amount_score = calculate_amount_deviation
    frequency_score = calculate_frequency_deviation
    mode_score = calculate_mode_deviation
    time_score = calculate_time_deviation

    # Calculate weighted risk score
    risk_score = (
      (amount_score * AMOUNT_WEIGHT / 100.0) +
      (frequency_score * FREQUENCY_WEIGHT / 100.0) +
      (mode_score * MODE_WEIGHT / 100.0) +
      (time_score * TIME_WEIGHT / 100.0)
    ).round

    # Determine decision
    decision = determine_decision(risk_score)

    {
      risk_score: risk_score,
      triggered_factors: @triggered_factors,
      decision: decision,
      amount_deviation_score: amount_score,
      frequency_deviation_score: frequency_score,
      mode_deviation_score: mode_score,
      time_deviation_score: time_score
    }
  end

  private

  def calculate_amount_deviation
    mean = @profile.average_transaction_amount || @amount

    # If this is the first transaction, no deviation
    return 0 if @profile.total_transactions.zero?

    # Calculate standard deviation from all user transactions
    transactions = @user.transactions.pluck(:amount)
    return 0 if transactions.empty?

    std_dev = calculate_standard_deviation(transactions, mean)

    # If std_dev is 0 (all transactions same amount), use a default
    std_dev = mean * 0.1 if std_dev.zero?

    # Calculate z-score
    z_score = ((@amount - mean) / std_dev).abs

    # Convert z-score to 0-100 scale
    # z-score > 3 is very unusual (99.7% of data within 3 std devs)
    score = [ (z_score / 3.0 * 100).round, 100 ].min

    @triggered_factors << "AMOUNT_DEVIATION" if score > 50

    score
  end

  def calculate_frequency_deviation
    # Count transactions in the last hour
    one_hour_ago = 1.hour.ago
    recent_count = @user.transactions.where("created_at >= ?", one_hour_ago).count

    # Define thresholds
    normal_limit = @profile.average_number_of_transactions_per_day || 10
    hourly_limit = [ normal_limit / 24.0, 1 ].max  # At least 1 per hour

    # Calculate score based on how much over the limit
    if recent_count <= hourly_limit
      score = 0
    else
      excess = recent_count - hourly_limit
      score = [ (excess / hourly_limit * 100).round, 100 ].min
    end

    @triggered_factors << "FREQUENCY_SPIKE" if score > 50

    score
  end

  def calculate_mode_deviation
    registered_modes = @profile.registered_payment_modes || []

    # If no modes registered yet, this is a new mode
    if registered_modes.empty?
      @triggered_factors << "NEW_MODE"
      return 60  # Moderate risk for first-time mode
    end

    # Check if current mode is registered
    if registered_modes.include?(@mode)
      0  # No deviation
    else
      @triggered_factors << "NEW_MODE"
      60  # Moderate risk for new mode
    end
  end

  def calculate_time_deviation
    current_hour = Time.current.hour

    # If no usual hours set, no deviation
    if @profile.usual_transaction_start_hour.nil? || @profile.usual_transaction_end_hour.nil?
      return 0
    end

    start_hour = @profile.usual_transaction_start_hour.hour
    end_hour = @profile.usual_transaction_end_hour.hour

    # Check if current time is within usual hours
    in_usual_range = if start_hour <= end_hour
                       current_hour >= start_hour && current_hour <= end_hour
    else
                       # Handle case where range crosses midnight
                       current_hour >= start_hour || current_hour <= end_hour
    end

    if in_usual_range
      0
    else
      # Calculate how far outside the range
      distance = if start_hour <= end_hour
                   [ start_hour - current_hour, current_hour - end_hour ].max
      else
                   # More complex for midnight crossing
                   [ (start_hour - current_hour) % 24, (current_hour - end_hour) % 24 ].min
      end

      score = [ (distance / 12.0 * 100).round, 100 ].min
      @triggered_factors << "TIME_ANOMALY" if score > 50
      score
    end
  end

  def calculate_standard_deviation(values, mean)
    return 0 if values.empty?

    variance = values.sum { |v| (v.to_f - mean) ** 2 } / values.size.to_f
    Math.sqrt(variance)
  end

  def determine_decision(risk_score)
    if risk_score < ALLOW_THRESHOLD
      "ALLOW"
    elsif risk_score < FLAG_THRESHOLD
      "FLAG"
    else
      "BLOCK"
    end
  end
end
