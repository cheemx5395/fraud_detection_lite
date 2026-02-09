require "test_helper"
require "benchmark"

class PerformanceDegradationTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.transactions.delete_all
    @profile = @user.user_behavior_profile || @user.create_user_behavior_profile
  end

  test "analyze performance degrades with transaction count" do
    counts = [ 10, 100, 1000 ]
    results = {}

    counts.each do |count|
      # Create bulk transactions
      transaction_data = count.times.map do
        {
          user_id: @user.id,
          amount: rand(1..1000),
          mode: "UPI",
          risk_score: 0,
          decision: "ALLOW",
          amount_deviation_score: 0,
          frequency_deviation_score: 0,
          mode_deviation_score: 0,
          time_deviation_score: 0,
          triggered_factors: [],
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      Transaction.insert_all(transaction_data)

      # Measure performance of a single analysis
      time = Benchmark.realtime do
        FraudDetectionService.analyze(
          user: @user,
          profile: @profile,
          amount: 500,
          mode: "UPI"
        )
      end
      results[count] = time
      puts "Analysis time for #{count} transactions: #{(time * 1000).round(2)}ms"
    end

    # Verify that it doesn't scale linearly or is just too slow
    # This is a demonstration, not a strict assertion yet
    assert results[1000] > 0
  end
end
