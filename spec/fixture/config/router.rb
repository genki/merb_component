Merb::Router.prepare do
  resources :comments
  resources :posts do |post|
    post.aggregates :comments
  end
  resource :admin, :controller => :admin do |admin|
    admin.aggregates :comments
  end

  default_routes
end
