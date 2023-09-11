Rails.application.routes.draw do
  get "welcome/index"
  get "welcome/user_session"

  get "component/:name/:session_id" => "component#name", :as => :component_named_default
  get "component/:name/expanded/:session_id" => "component#name", :as => :component_named_expanded
  get "component/:name/settings/:session_id" => "component#name", :as => :component_named_settings

  get "ping" => "status#ping"
  get "check" => "status#check"
  get "clear_cache" => "status#clear_cache"

  if defined?(Sidekiq)
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end

  namespace :api do
    resources :widgets
    patch "widgets/:id/revise" => "widgets#revise"
    patch "widgets/:id/merge" => "widgets#merge"
    post "events" => "events#create"
    patch "user_widgets", to: "user_widgets#update_order"
    delete "user_widgets/:id", to: "user_widgets#destroy", as: :destroy_user_widget
    post "user_widgets/:id/restore", to: "user_widgets#restore", as: :restore_user_widget
    post "jwt" => "jwt#index"
  end

  root "welcome#index"
end
