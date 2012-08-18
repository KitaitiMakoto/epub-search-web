EpubSearch::Application.routes.draw do
  resources :contents
  resources :books
  resources :users, only: [:new, :create, :destroy]
  resource :session, only: [:new, :create, :destroy]
end
