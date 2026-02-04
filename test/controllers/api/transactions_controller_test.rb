require "test_helper"

class Api::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @headers = authenticated_headers(@user)
  end

  test "should get index" do
    get api_transactions_url, headers: @headers, as: :json
    assert_response :success
  end

  test "should create transaction" do
    assert_difference("Transaction.count") do
      post api_transactions_url,
           params: { amount: 500, mode: "UPI" },
           headers: @headers,
           as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["data"]["id"]
  end

  test "should handle bulk ingestion" do
    csv_content = "amount,mode,created_at\n100,UPI,2026-01-01 10:00:00"
    file = fixture_file_upload(Tempfile.new([ "test", ".csv" ]).tap { |f| f.write(csv_content); f.rewind }.path, "text/csv")

    assert_difference("Transaction.count", 1) do
      post bulk_api_transactions_url,
           params: { file: file },
           headers: @headers
    end

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response["data"]["processed_rows"]
  end

  test "should return unauthorized if not logged in" do
    get api_transactions_url, as: :json
    assert_response :unauthorized
  end
end
