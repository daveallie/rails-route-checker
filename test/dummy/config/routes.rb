Rails.application.routes.draw do
  resources :articles, only: [:index_erb, :index_haml]
  resources :articles_api, only: :index
end
