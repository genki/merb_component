Merb::Router.prepare do
  resources :posts do |posts|
    posts.match("/:action").to(:controller => :posts)
    posts.match("/:action/:id").to(:controller => :posts)
    posts.resources :comments#, :controller => :posts
  end
  resource :admin, :controller => :admin do |admin|
    admin.match("/:action").to(:controller => :admin)
    admin.match("/:action/:id").to(:controller => :admin)
    admin.resources :comments#, :controller => :admin
  end

  default_routes
end
