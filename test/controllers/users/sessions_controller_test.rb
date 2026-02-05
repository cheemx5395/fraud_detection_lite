require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should login successfully" do
    post "/login", params: { email: @user.email, password: "password123" }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["token"]
  end

  test "should fail login with invalid password" do
    post "/login", params: { email: @user.email, password: "wrong_password" }, as: :json
    assert_response :unauthorized
  end

  test "should logout successfully" do
    headers = authenticated_headers(@user)
    delete "/api/logout", headers: headers, as: :json
    assert_response :success
  end

  test "should return error on logout without session" do
    delete "/api/logout", as: :json
    assert_response :unauthorized
  end
end
