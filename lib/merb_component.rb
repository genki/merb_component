# make sure we're running inside Merb
if defined?(Merb::Plugins)

  load_dependency "merb-slices", :immediate => true
  Merb::Slices::register(__FILE__)

  module MerbComponent
    def self.loaded
      require 'merb_component/controller_ext'
      require 'merb_component/resource_ext'
      require 'merb_component/router_ext'
    end
  end

  # Merb gives you a Merb::Plugins.config hash...feel free to put your stuff in
  # your piece of it
  Merb::Plugins.config[:merb_component] = {
  }
  
  Merb::BootLoader.before_app_loads do
    # require code that must be loaded before the application
  end
  
  Merb::BootLoader.after_app_loads do
    # code that can be required after the application loads
  end
  
  Merb::Plugins.add_rakefiles "merb_component/merbtasks"
end
