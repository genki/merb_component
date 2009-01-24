$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'merb-core'
require 'merb-core/plugins'
require 'merb_component'
require "spec" # Satisfies Autotest and anyone else not using the Rake tasks

dependency "dm-core"
dependency "dm-aggregates"
dependency "merb-action-args"
dependency "merb-helpers"

use_orm :datamapper
use_test :rspec
use_template_engine :erb

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.disable(:initfile)
Merb.start_environment(
  :testing      => true,
  :adapter      => 'runner',
  :environment  => ENV['MERB_ENV'] || 'test',
  :merb_root    => File.dirname(__FILE__) / 'fixture',
  :log_file     => File.dirname(__FILE__) / '..' / "merb_test.log"
)
DataMapper.setup(:default, "sqlite3::memory:")

Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
  config.before(:all){DataMapper.auto_migrate!}
end
