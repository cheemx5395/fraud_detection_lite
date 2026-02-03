Rails.application.routes.draw do
  devise_for :users,
             path: "",
             path_names: {
               sign_in: "login",
               sign_out: "api/logout"
             },
             controllers: {
               sessions: "users/sessions",
               registrations: "users/registrations"
             },
             skip: [ :registrations ]

  devise_scope :user do
    post "signup", to: "users/registrations#create"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
