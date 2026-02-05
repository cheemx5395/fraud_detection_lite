class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  def jwt_payload
    {
      "userid" => id,
      "name" => name,
      "email" => email
    }
  end

  # Associations
  has_one :user_behavior_profile, dependent: :destroy
  has_many :transactions, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Generate JTI before creating user
  before_create :generate_jti

  # Create behavior profile after user is created
  after_create :create_default_behavior_profile

  private

  def generate_jti
    self.jti = SecureRandom.uuid
  end

  def create_default_behavior_profile
    create_user_behavior_profile
  end
end
