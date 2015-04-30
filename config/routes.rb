ActionController::Routing::Routes.draw do |map|
  map.resources :commands

  map.connect 'backup_jobs/queue.xml', :controller => 'backup_jobs', :action => 'queue'

  map.redo '/backup_jobs/:id/redo_last', :controller => 'backup_jobs', :action => 'redo_last'
  map.mark_failed '/backup_jobs/:id/mark_failed', :controller => 'backup_jobs', :action => 'mark_failed'

  map.resources :backup_jobs

  map.resources :settings

  map.resources :roles_users

  map.resources :users, :has_many => :roles
  map.login 'login', :controller => 'user_sessions', :action => 'new'  
  map.logout 'logout', :controller => 'user_sessions', :action => 'destroy'  
  map.resources :user_sessions
  
  map.resources :profiles, :has_many => [:excludes, :includes, :splits]
  map.resources :quirks

  map.resources :backup_servers

  map.resources :servers
  map.connect '/stats/server/:subset/:id.:format', :controller => 'servers', :action => 'job_stats', :format => /json/, :subset => /\w+/

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "dashboard"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
