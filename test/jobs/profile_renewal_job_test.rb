require "test_helper"

class ProfileRenewalJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @user.transactions.delete_all
    @profile = @user.user_behavior_profile || @user.create_user_behavior_profile
  end

  test "should recalibrate all user profiles" do
    # Create some transactions
    @user.transactions.create!(amount: 100, mode: "UPI", risk_score: 0, decision: "ALLOW", amount_deviation_score: 0, frequency_deviation_score: 0, mode_deviation_score: 0, time_deviation_score: 0)
    @user.transactions.create!(amount: 200, mode: "CARD", risk_score: 0, decision: "ALLOW", amount_deviation_score: 0, frequency_deviation_score: 0, mode_deviation_score: 0, time_deviation_score: 0)

    # Manually set something wrong to verify recalibration
    @profile.update!(total_transactions: 0, average_transaction_amount: 0)

    ProfileRenewalJob.perform_now

    @profile.reload
    assert_equal 2, @profile.total_transactions
    assert_equal 150.0, @profile.average_transaction_amount.to_f
    assert_includes @profile.registered_payment_modes, "UPI"
    assert_includes @profile.registered_payment_modes, "CARD"
  end
end
