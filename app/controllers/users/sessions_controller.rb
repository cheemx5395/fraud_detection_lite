class Users::SessionsController < Devise::SessionsController
  respond_to :json
  before_action :authenticate_user!, only: [ :destroy ]
  skip_before_action :authenticate_user!, only: [ :create ]
  skip_before_action :verify_signed_out_user

  def create
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password])
      # Sign in the user to generate JWT token with JTI
      sign_in(user, store: false)
      token = request.env["warden-jwt_auth.token"]

      render json: {
        message: "Logged in successfully",
        token: token
      }, status: :ok
    else
      render json: {
        message: "Invalid email or password"
      }, status: :unauthorized
    end
  end

  def destroy
    unless current_user
      render json: { error: "No active session" }, status: :unauthorized
      return
    end

    # JWT revocation is handled automatically by warden-jwt_auth middleware
    render json: {
      message: "Logged out successfully"
    }, status: :ok
  end

  private

  def respond_to_on_destroy
    render json: {
      message: "Logged out successfully"
    }, status: :ok
  end
end
