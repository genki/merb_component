Merb::Router.prepare do
  resources :posts
  resources :comments

  default_routes
end
