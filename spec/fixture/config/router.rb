Merb::Router.prepare do
  resources :posts do |posts|
    posts.match("/:action").to(:controller => :posts)
    posts.resources :comments#, :controller => :posts
  end
  resource :admin do |admin|
    admin.match("/:action").to(:controller => :admin)
    admin.resources :comments#, :controller => :admin
  end

  default_routes
end
