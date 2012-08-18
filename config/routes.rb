EpubSearch::Application.routes.draw do
  resources :contents

  resources :books

  resources :users

  resource :session, only: [:new, :create, :destroy]
end
