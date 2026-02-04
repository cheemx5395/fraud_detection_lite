class ProfileUpdateService
  def self.update_profile(profile, transaction)
    new(profile, transaction).update
  end

  def initialize(profile, transaction)
    @profile = profile
    @transaction = transaction
  end

  def update
    update_transaction_counts
    update_average_amount
    update_max_amount
    update_payment_modes
    update_usual_hours
    update_daily_transaction_average

    @profile.save
  end

  private

  def update_transaction_counts
    @profile.total_transactions += 1
    @profile.allowed_transactions += 1 if @transaction.decision == "ALLOW"
  end

  def update_average_amount
    total = @profile.total_transactions
    current_avg = @profile.average_transaction_amount || 0

    # Calculate running average
    new_avg = ((current_avg * (total - 1)) + @transaction.amount) / total
    @profile.average_transaction_amount = new_avg
  end

  def update_max_amount
    current_max = @profile.max_transaction_amount_seen || 0
    @profile.max_transaction_amount_seen = [ @transaction.amount, current_max ].max
  end

  def update_payment_modes
    modes = @profile.registered_payment_modes || []
    unless modes.include?(@transaction.mode)
      @profile.registered_payment_modes = (modes + [ @transaction.mode ]).uniq
    end
  end

  def update_usual_hours
    current_time = @transaction.created_at

    if @profile.usual_transaction_start_hour.nil?
      @profile.usual_transaction_start_hour = current_time
      @profile.usual_transaction_end_hour = current_time
    else
      # Expand the range if needed
      if current_time.hour < @profile.usual_transaction_start_hour.hour
        @profile.usual_transaction_start_hour = current_time
      end

      if current_time.hour > @profile.usual_transaction_end_hour.hour
        @profile.usual_transaction_end_hour = current_time
      end
    end
  end

  def update_daily_transaction_average
    # Calculate transactions per day over last 30 days
    thirty_days_ago = 30.days.ago
    recent_transactions = @profile.user.transactions.where("created_at >= ?", thirty_days_ago).count
    days_active = [ ((Time.current - [ @profile.user.created_at, thirty_days_ago ].max) / 1.day).ceil, 1 ].max

    @profile.average_number_of_transactions_per_day = (recent_transactions.to_f / days_active).round
  end
end
