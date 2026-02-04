ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup fixtures
    fixtures :users, :user_behavior_profiles, :transactions

    # Add more helper methods to be used by all tests here...
    def authenticated_headers(user)
      # We need to include the Warden::JWTAuth::UserEncoder to generate the token
      # Or just use the Devise helper if available.
      # Since we are using devise-jwt, we can manually generate the token.

      # For simplicity in integration tests, we can use the login endpoint
      # But it's better to have a direct way.

      payload = { "sub" => user.id, "jti" => user.jti, "scp" => "user" }
      token = JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key || "your-secret-key")
      { "Authorization" => "Bearer #{token}" }
    end
  end
end
