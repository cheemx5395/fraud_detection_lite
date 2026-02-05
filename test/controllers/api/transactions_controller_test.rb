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

  test "should show transaction" do
    transaction = transactions(:one)
    get api_transaction_url(transaction), headers: @headers, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal transaction.id, json_response["data"]["id"]
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

  test "should return error on invalid creation" do
    post api_transactions_url,
         params: { amount: -1, mode: "UPI" },
         headers: @headers,
         as: :json
    assert_response :unprocessable_entity
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

  test "should handle fully failing bulk ingestion" do
    csv_content = "amount,mode,created_at\ninvalid,INVALID,not-a-date"
    file = fixture_file_upload(Tempfile.new([ "test", ".csv" ]).tap { |f| f.write(csv_content); f.rewind }.path, "text/csv")

    post bulk_api_transactions_url,
         params: { file: file },
         headers: @headers

    assert_response :unprocessable_entity
  end

  test "should return unauthorized if not logged in" do
    get api_transactions_url, as: :json
    assert_response :unauthorized
  end

  test "should return error when set_transaction fails" do
    get api_transaction_url(id: 999999), headers: @headers, as: :json
    assert_response :not_found
  end

  test "should return error when no file provided for bulk" do
    post bulk_api_transactions_url, headers: @headers, as: :json
    assert_response :bad_request
  end
end
