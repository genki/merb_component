Merb::Router.prepare do
  resources :posts do |posts|
    posts.resources :comments
  end

  default_routes
end
