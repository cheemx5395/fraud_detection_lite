class UserBehaviorProfile < ApplicationRecord
  belongs_to :user

  # Enum for payment modes, mapping to the custom postgres type
  # Note: Rails 7+ handling of array enums can be tricky, but since we use a custom type,
  # we might just treat it as an array of strings at the application level validation.
  # For now, we won't strictly validate the enum here to avoid conflicts with the custom DB type.
end
