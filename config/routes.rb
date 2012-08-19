EpubSearch::Application.routes.draw do
  resources :contents, only: [:index]
  resources :books, only: [:index, :show, :new, :create, :destroy]
  resources :users, only: [:new, :create, :destroy]
  resource :session, only: [:new, :create, :destroy]
end
