class ProfileRenewalJob < ApplicationJob
  queue_as :default

  def perform
    UserBehaviorProfile.find_each do |profile|
      recalibrate_profile(profile)
    end
  end

  private

  def recalibrate_profile(profile)
    user = profile.user
    transactions = user.transactions.allowed.order(:created_at)

    return if transactions.empty?

    # Reset profile stats
    profile.total_transactions = user.transactions.count
    profile.allowed_transactions = transactions.count

    amounts = transactions.pluck(:amount)
    profile.average_transaction_amount = amounts.sum / amounts.size.to_f
    profile.max_transaction_amount_seen = amounts.max

    profile.registered_payment_modes = transactions.pluck(:mode).uniq

    profile.usual_transaction_start_hour = transactions.minimum(:created_at)
    profile.usual_transaction_end_hour = transactions.maximum(:created_at)

    # Daily average over last 30 days
    thirty_days_ago = 30.days.ago
    recent_count = user.transactions.where("created_at >= ?", thirty_days_ago).count
    days_active = [ ((Time.current - [ user.created_at, thirty_days_ago ].max) / 1.day).ceil, 1 ].max
    profile.average_number_of_transactions_per_day = (recent_count.to_f / days_active).round

    profile.save!
  end
end
