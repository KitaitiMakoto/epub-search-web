EpubSearch::Application.routes.draw do
  resources :books, only: [:index, :show, :new, :create, :destroy] do
    resources :contents, only: [:index, :show]
  end
  resources :users, only: [:new, :create, :destroy]
  resource :session, only: [:new, :create, :destroy]
end
