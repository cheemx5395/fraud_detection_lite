require "test_helper"

class FraudDetectionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one) # Assumes fixtures exist or I'll create them
    @user.transactions.delete_all
    @profile = @user.user_behavior_profile || @user.create_user_behavior_profile
  end

  test "should allow normal transaction" do
    @profile.update!(average_transaction_amount: 500, total_transactions: 10)

    result = FraudDetectionService.analyze(
      user: @user,
      profile: @profile,
      amount: 400,
      mode: "UPI"
    )

    assert_equal "ALLOW", result[:decision]
    assert result[:risk_score] < 30
  end

  test "should block massive amount deviation" do
    @profile.update!(average_transaction_amount: 500, total_transactions: 10)
    # Add some history for std_dev
    5.times { @user.transactions.create!(amount: 500, mode: "UPI", risk_score: 0, decision: "ALLOW", amount_deviation_score: 0, frequency_deviation_score: 0, mode_deviation_score: 0, time_deviation_score: 0) }
    @profile.reload

    result = FraudDetectionService.analyze(
      user: @user,
      profile: @profile,
      amount: 100000,
      mode: "NETBANKING"
    )

    assert_equal "BLOCK", result[:decision]
    assert_includes result[:triggered_factors], "AMOUNT_DEVIATION"
  end

  test "should ignore amounts smaller than average" do
    @profile.update!(average_transaction_amount: 1000, total_transactions: 10)

    result = FraudDetectionService.analyze(
      user: @user,
      profile: @profile,
      amount: 500,
      mode: "UPI"
    )

    assert_equal 0, result[:amount_deviation_score]
  end

  test "should flag frequency spike" do
    # Create 5 transactions in last hour
    5.times { @user.transactions.create!(amount: 100, mode: "UPI", risk_score: 0, decision: "ALLOW", created_at: Time.current, amount_deviation_score: 0, frequency_deviation_score: 0, mode_deviation_score: 0, time_deviation_score: 0) }

    result = FraudDetectionService.analyze(
      user: @user,
      profile: @profile,
      amount: 100,
      mode: "UPI"
    )

    assert_includes result[:triggered_factors], "FREQUENCY_SPIKE"
  end
end
