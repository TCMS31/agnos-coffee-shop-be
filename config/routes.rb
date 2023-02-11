# frozen_string_literal: true

Rails.application.routes.draw do
  # Routes are listed explicitly rather than with a bare `resources` call: the
  # API does not offer an update for orders (a placed order is a snapshot) or
  # for order items (changing a line's quantity would have to reconcile stock),
  # and a route that reaches an action a controller never opted into is a bug
  # waiting to happen.
  namespace :api do
    namespace :v1 do
      resources :customers
      resources :items
      resources :discounts
      resources :orders, only: %i[index show create destroy]
      resources :order_items, only: %i[index show create destroy]
    end
  end

  get '/up', to: 'health#show'
end
