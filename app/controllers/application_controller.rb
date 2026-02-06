class ApplicationController < ActionController::API
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    render json: { error: exception.message }, status: :forbidden
  end

  rescue_from JWT::DecodeError, JWT::ExpiredSignature do |exception|
    render json: { error: "Invalid or expired token" }, status: :unauthorized
  end
end
