RetconWeb::Application.routes.draw do
  resources :commands
  match 'backup_jobs/queue.xml' => 'backup_jobs#queue'
  match '/backup_jobs/:id/redo_last' => 'backup_jobs#redo_last', :as => :redo
  match '/backup_jobs/:id/mark_failed' => 'backup_jobs#mark_failed', :as => :mark_failed
  resources :backup_jobs
  resources :settings
  resources :roles_users
  resources :users
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  resources :user_sessions
  resources :profiles
  resources :quirks
  resources :backup_servers
  resources :servers
  match '/stats/server/:subset/:id.:format' => 'servers#job_stats', :format => /json/, :subset => /\w+/
  match '/:controller(/:action(/:id))'
  #match '/' => 'dashboard#index'
  root :to => 'dashboard#index'
end
