Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      resources :customers
      resources :items
      resources :orders
      resources :order_items
      resources :discounts
    end
  end
end
