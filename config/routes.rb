Rails.application.routes.draw do
  # 未ログイン時のルートパスをログイン画面に設定
  root 'admin/sessions#new'
  post '/login', to: 'admin/sessions#create'
  delete '/logout', to: 'admin/sessions#destroy'

  namespace :admin do
    # 調整中 ログイン後のダッシュボードルート（Turbo Frames用のメインレイアウト）
    get 'dashboard', to: 'dashboard#index', as: :root
    
    resources :users, only: [:index] do
      resources :gift_codes, only: [:create]
    end

    resources :gift_codes
    
    resources :administrators
    
    resources :books
  end

  if Rails.env.development?
    require 'sidekiq/web'
    mount LetterOpenerWeb::Engine, at: '/letter_opener'
    mount Sidekiq::Web, at: '/sidekiq'
  end
end
