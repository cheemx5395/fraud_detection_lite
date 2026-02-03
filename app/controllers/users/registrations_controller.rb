class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    build_resource(sign_up_params)

    resource.save
    if resource.persisted?
      render json: {
        message: "Signup Success!",
        id: resource.id
      }, status: :ok
    else
      render json: {
        message: resource.errors.full_messages.first
      }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
