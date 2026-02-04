require "test_helper"

class BulkIngestionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.transactions.delete_all
    @profile = @user.user_behavior_profile || @user.create_user_behavior_profile
    @csv_content = <<~CSV
      amount,mode,created_at
      100,UPI,2026-01-01 10:00:00
      200,CARD,2026-01-02 11:00:00
    CSV
    @file = Tempfile.new([ "test", ".csv" ])
    @file.write(@csv_content)
    @file.rewind
  end

  teardown do
    @file.close
    @file.unlink
  end

  test "should process CSV correctly" do
    summary = BulkIngestionService.process(@user, @file.path, "test.csv")

    assert_equal 2, summary[:total_rows]
    assert_equal 2, summary[:processed_rows]
    assert_equal 0, summary[:failed_rows]
    assert_equal 2, @user.transactions.count
  end

  test "should handle missing headers" do
    bad_file = Tempfile.new([ "bad", ".csv" ])
    bad_file.write("wrong,header\n100,UPI")
    bad_file.rewind

    summary = BulkIngestionService.process(@user, bad_file.path, "bad.csv")
    assert_includes summary[:errors].first, "Missing required headers"

    bad_file.close
    bad_file.unlink
  end
end
