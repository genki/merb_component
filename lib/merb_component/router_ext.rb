Merb::Router.extensions do
  def aggregates(resource, options = {})
    options[:controller] ||= @params[:controller]
    match("/:action/:id").to(options)
    match("/:action(.:format)").to(options)
    resources resource
  end
end
